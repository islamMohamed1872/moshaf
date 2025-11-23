// podcast_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/models/episode_model.dart';
import '../../services/youtubr_services.dart';
import 'podcast_states.dart';

class PodcastCubit extends Cubit<PodcastStates> {
  final YouTubeService yt;
  PodcastCubit({required this.yt}) : super(PodcastInitial());
  static PodcastCubit get(context) => BlocProvider.of(context);
  final List<Map<String, String>> originalList = [
    {
      "type": "playlist",
      "title": "دين و طين",
      "playlist": "PLp0HPxdzjjMhcFyOYQ6dvn7fkxiFnuQCg",
      "image": "https://i.ytimg.com/vi/5qzKaozM8ks/hqdefault.jpg",
    },
    {
      "type": "playlist",
      "title": "إيه المشكلة",
      "playlist": "PLlXQj2VGUTmdUP1KDQ9pkmKJU-KDNOkwt",
      "image": "https://i.ytimg.com/vi/1XpFCr3yFSY/hqdefault.jpg",
    },
    {
      "type": "playlist",
      "title": "Podcast البودكاست",
      "playlist": "PL5isa5XjlZ5pH8vT0TJO9qZrRiZcrWuDp",
      "image": "https://i.ytimg.com/vi/scu4-irtB8k/hqdefault.jpg",
    },
    {
      "type": "playlist",
      "title": "سلسلة نقض الإلحاد",
      "playlist": "PLSFJcWy6euuA_Ux76wLLUwR7HPpKL9rd-",
      "image": "https://i.ytimg.com/vi/FP_Uv4zq_X0/hqdefault.jpg",
    },
    {
      "type": "playlist",
      "title": "الموسم الرابع | فاهم بودكاست",
      "playlist": "PLSFJcWy6euuDw9Ag0y0eGztNHlL1UwqUH",
      "image": "https://i.ytimg.com/vi/zRvZtwTSM6Q/hqdefault.jpg",
    },
    {
      "type": "playlist",
      "title": "سلسلة لازم تتحرر",
      "playlist": "PLSFJcWy6euuAZPTasEUJRSrKEp85h6HPY",
      "image": "https://i.ytimg.com/vi/agFMbV32JIc/hqdefault.jpg",
    },
    {
      "type": "playlist",
      "title": "الموسم الثالث | فاهم بودكاست",
      "playlist": "PLSFJcWy6euuD3uH4KATSQPjwnph7wT2yY",
      "image": "https://i.ytimg.com/vi/_iAaHmAdGBw/hqdefault.jpg",
    },
    {
      "type": "playlist",
      "title": "الموسم الثاني | فاهم بودكاست",
      "playlist": "PLSFJcWy6euuA1fybGAh3MO-D2ODE_ccsB",
      "image": "https://i.ytimg.com/vi/si994Z9BAr8/hqdefault.jpg",
    },
    {
      "type": "playlist",
      "title": "سلسلة تذوق العبادات",
      "playlist": "PLSFJcWy6euuDj6XSqBM-MmKhCyrXK_ywv",
      "image": "https://i.ytimg.com/vi/63_AOCldyXo/hqdefault.jpg",
    },
    {
      "type": "playlist",
      "title": "الموسم الأول | فاهم بودكاست",
      "playlist": "PLSFJcWy6euuA1W3YoDriyB6O9_huT-BgQ",
      "image": "https://i.ytimg.com/vi/q8EYrvWn4n0/hqdefault.jpg",
    },
    {
      "type": "video",
      "title": "كيف تنجح العلاقات مع ياسر الحزيمي | بودكاست فنجان",
      "id": "pJ0auP7dbcY",
      "image": "https://i.ytimg.com/vi/pJ0auP7dbcY/hq720.jpg",
    },
  ];

  List<Map<String, String>> filteredList = [];
  List<Episode> episodes = [];
  List<Episode> filteredEpisodes = [];

  /// Fetch by playlistId or playlist URL
  Future<void> fetchPlaylist(String playlistUrlOrId) async {
    emit(PodcastLoading());
    try {
      final playlistId = YouTubeService.extractPlaylistId(playlistUrlOrId) ?? playlistUrlOrId;
      final items = await yt.fetchPlaylistItems(playlistId: playlistId);
      final videoIds = items.map((e) => e['videoId'] as String).toList();
      final contents = await yt.fetchVideosContentDetails(videoIds: videoIds);

      final episodes = items.map((it) {
        final vid = it['videoId'] as String;
        final content = contents[vid] as Map<String, dynamic>?;
        return Episode.fromMap(snippet: it, contentMap: content);
      }).toList();
      this.episodes = episodes;
      emit(PodcastLoaded(playlistId: playlistId, episodes: episodes));
    } catch (e, st) {
      print(e);
      emit(PodcastError(e.toString()));
    }
  }



  void search(String query) {
    final q = normalizeArabic(query.toLowerCase());

    if (q.isEmpty) {
      emit(PodcastFilterState());
      return;
    }

    filteredList = originalList.where((p) {
      final title = normalizeArabic(p['title']!.toLowerCase());
      return title.contains(q);
    }).toList();

    emit(PodcastFilterState());
  }

  void searchEpisode(String query) {
    final q = normalizeArabic(query.toLowerCase());

    if (q.isEmpty) {
      filteredEpisodes = episodes; // return full list
      emit(PodcastFilterState());
      return;
    }

    filteredEpisodes = episodes.where((episode) {
      final title = normalizeArabic(episode.title.toLowerCase());
      return title.contains(q);
    }).toList();

    emit(PodcastFilterState());
  }

  String normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[أإآا]'), 'ا') // Alef variations → ا
        .replaceAll('ى', 'ي')               // Alif Maqsura → ي
        .replaceAll('ؤ', 'و')               // Waw hamza → و
        .replaceAll('ئ', 'ي')               // Yeh hamza → ي
        .replaceAll('ة', 'ه')               // Ta marbuta → ه
        .replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), '') // remove Latin/punctuation (optional)
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '') // remove tashkeel
        .trim();
  }


}
