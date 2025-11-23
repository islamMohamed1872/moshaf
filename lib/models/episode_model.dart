// episode_model.dart
class Episode {
  final String videoId;
  final String title;
  final String description;
  final String? thumbnail;
  final String durationIso; // ISO8601 duration from YouTube (e.g. PT1H4M2S)
  final String durationReadable; // e.g. 1:04:02
  final String? publishedAt;
  final String? viewCount;

  Episode({
    required this.videoId,
    required this.title,
    required this.description,
    required this.durationIso,
    required this.durationReadable,
    this.thumbnail,
    this.publishedAt,
    this.viewCount,
  });

  factory Episode.fromMap({
    required Map<String, dynamic> snippet,
    required Map<String, dynamic>? contentMap,
  }) {
    final videoId = snippet['videoId'] as String;
    final title = snippet['title'] as String? ?? '';
    final description = snippet['description'] as String? ?? '';
    final thumbnail = snippet['thumbnail'] as String?;
    final publishedAt = snippet['publishedAt'] as String?;
    final content = contentMap ?? {};
    final durationIso = (content['duration'] as String?) ?? '';
    final viewCount = (content['viewCount']?.toString());

    return Episode(
      videoId: videoId,
      title: title,
      description: description,
      thumbnail: thumbnail,
      durationIso: durationIso,
      durationReadable: _readableDuration(durationIso),
      publishedAt: publishedAt,
      viewCount: viewCount,
    );
  }

  /// Convert ISO8601 duration (PT#H#M#S) to h:mm:ss or m:ss
  static String _readableDuration(String iso) {
    if (iso.isEmpty) return '0:00';
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(iso);
    if (match == null) return '0:00';
    final h = int.tryParse(match.group(1) ?? '') ?? 0;
    final m = int.tryParse(match.group(2) ?? '') ?? 0;
    final s = int.tryParse(match.group(3) ?? '') ?? 0;
    String two(int v) => v.toString().padLeft(2, '0');
    if (h > 0) return '$h:${two(m)}:${two(s)}';
    return '${m}:${two(s)}';
  }
}
