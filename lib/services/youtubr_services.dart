// youtube_service.dart
import 'package:dio/dio.dart';

class YouTubeService {
  final String apiKey;
  final Dio _dio;

  YouTubeService({required this.apiKey}) : _dio = Dio();

  /// Fetch playlist items (title, videoId, snippet, thumbnails)
  /// Handles pagination; returns list of maps (each contains videoId, title, description, thumbnail).
  Future<List<Map<String, dynamic>>> fetchPlaylistItems({
    required String playlistId,
    int maxResults = 50,
  }) async {
    List<Map<String, dynamic>> items = [];
    String? pageToken;

    do {
      final url =
          'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=$playlistId&maxResults=$maxResults&key=$apiKey${pageToken != null ? "&pageToken=$pageToken" : ""}';
      final res = await _dio.get(url);
      if (res.statusCode != 200) break;

      final data = res.data as Map<String, dynamic>;
      final List<dynamic> results = data['items'] ?? [];

      for (final item in results) {
        final snippet = item['snippet'] as Map<String, dynamic>;
        final resourceId = snippet['resourceId'] as Map<String, dynamic>?;
        final videoId = resourceId?['videoId'] as String?;
        if (videoId == null) continue;

        final thumbnails = snippet['thumbnails'] as Map<String, dynamic>?;
        final defaultThumb =
            thumbnails?['high'] ?? thumbnails?['standard'] ?? thumbnails?['default'];

        items.add({
          'videoId': videoId,
          'title': snippet['title'] ?? '',
          'description': snippet['description'] ?? '',
          'thumbnail': (defaultThumb != null) ? defaultThumb['url'] : null,
          'publishedAt': snippet['publishedAt'],
        });
      }

      pageToken = data['nextPageToken'] as String?;
    } while (pageToken != null);

    return items;
  }

  /// Fetch videos details for a list of videoIds (contentDetails -> duration)
  /// Accepts up to 50 ids per request.
  Future<Map<String, dynamic>> fetchVideosContentDetails({
    required List<String> videoIds,
  }) async {
    final Map<String, dynamic> result = {};
    if (videoIds.isEmpty) return result;

    // YouTube allows up to 50 ids per call
    const chunk = 50;
    for (var i = 0; i < videoIds.length; i += chunk) {
      final sub = videoIds.sublist(i, (i + chunk) > videoIds.length ? videoIds.length : (i + chunk));
      final ids = sub.join(',');
      final url =
          'https://www.googleapis.com/youtube/v3/videos?part=contentDetails,statistics&id=$ids&key=$apiKey';
      final res = await _dio.get(url);
      if (res.statusCode != 200) continue;
      final data = res.data as Map<String, dynamic>;
      final List<dynamic> items = data['items'] ?? [];
      for (final it in items) {
        final id = it['id'] as String?;
        final content = it['contentDetails'] as Map<String, dynamic>?;
        final duration = content?['duration'] as String?;
        final stats = it['statistics'] as Map<String, dynamic>?;
        final viewCount = stats?['viewCount'];
        result[id ?? ''] = {
          'duration': duration ?? '',
          'viewCount': viewCount,
        };
      }
    }
    return result;
  }

  /// Utility: extract playlist id from common playlist urls
  static String? extractPlaylistId(String urlOrId) {
    // If user gives a full URL like:
    // https://www.youtube.com/playlist?list=PL...
    // or https://www.youtube.com/watch?v=...&list=PL...
    try {
      if (urlOrId.contains("list=")) {
        final uri = Uri.parse(urlOrId);
        return uri.queryParameters['list'];
      }
    } catch (_) {}
    // fallback: assume it's already the id
    return urlOrId;
  }
}
