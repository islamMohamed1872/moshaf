// podcast_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/models/episode_model.dart';
import '../../services/youtube_services.dart';
import 'podcast_states.dart';

enum PodcastCategory { all, deen, dunya }


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
      "category": "deen"
    },
    {
      "type": "playlist",
      "title": "إيه المشكلة",
      "playlist": "PLlXQj2VGUTmdUP1KDQ9pkmKJU-KDNOkwt",
      "image": "https://i.ytimg.com/vi/1XpFCr3yFSY/hqdefault.jpg",
      "category": "deen"
    },
    {
      "type": "playlist",
      "title": "Podcast البودكاست",
      "playlist": "PL5isa5XjlZ5pH8vT0TJO9qZrRiZcrWuDp",
      "image": "https://i.ytimg.com/vi/scu4-irtB8k/hqdefault.jpg",
      "category": "dunya"
    },
    {
      "type": "playlist",
      "title": "سلسلة نقض الإلحاد",
      "playlist": "PLSFJcWy6euuA_Ux76wLLUwR7HPpKL9rd-",
      "image": "https://i.ytimg.com/vi/FP_Uv4zq_X0/hqdefault.jpg",
      "category": "deen"
    },
    {
      "type": "playlist",
      "title": "الموسم الرابع | فاهم بودكاست",
      "playlist": "PLSFJcWy6euuDw9Ag0y0eGztNHlL1UwqUH",
      "image": "https://i.ytimg.com/vi/zRvZtwTSM6Q/hqdefault.jpg",
      "category": "deen"
    },
    {
      "type": "playlist",
      "title": "سلسلة لازم تتحرر",
      "playlist": "PLSFJcWy6euuAZPTasEUJRSrKEp85h6HPY",
      "image": "https://i.ytimg.com/vi/agFMbV32JIc/hqdefault.jpg",
      "category": "dunya"
    },
    {
      "type": "playlist",
      "title": "الموسم الثالث | فاهم بودكاست",
      "playlist": "PLSFJcWy6euuD3uH4KATSQPjwnph7wT2yY",
      "image": "https://i.ytimg.com/vi/_iAaHmAdGBw/hqdefault.jpg",
      "category": "deen"
    },
    {
      "type": "playlist",
      "title": "الموسم الثاني | فاهم بودكاست",
      "playlist": "PLSFJcWy6euuA1fybGAh3MO-D2ODE_ccsB",
      "image": "https://i.ytimg.com/vi/si994Z9BAr8/hqdefault.jpg",
      "category": "deen"
    },
    {
      "type": "playlist",
      "title": "سلسلة تذوق العبادات",
      "playlist": "PLSFJcWy6euuDj6XSqBM-MmKhCyrXK_ywv",
      "image": "https://i.ytimg.com/vi/63_AOCldyXo/hqdefault.jpg",
      "category": "deen"
    },
    {
      "type": "playlist",
      "title": "الموسم الأول | فاهم بودكاست",
      "playlist": "PLSFJcWy6euuA1W3YoDriyB6O9_huT-BgQ",
      "image": "https://i.ytimg.com/vi/q8EYrvWn4n0/hqdefault.jpg",
      "category": "deen"
    },
    {
      "type": "video",
      "title": "كيف تنجح العلاقات مع ياسر الحزيمي | بودكاست فنجان",
      "id": "pJ0auP7dbcY",
      "image": "https://i.ytimg.com/vi/pJ0auP7dbcY/hq720.jpg",
      "category": "dunya"
    },
  ];

  List<Map<String, String>> filteredList = [];

  /// ===============================
  /// CATEGORY STATE
  /// ===============================
  PodcastCategory selectedCategory = PodcastCategory.all;

  /// ===============================
  /// PUBLIC METHODS USED BY UI
  /// ===============================

  /// Called when user taps a chip
  void changeCategory(PodcastCategory category) {
    selectedCategory = category;
    emit(PodcastFilterState());
  }

  /// Final visible list (category + search)
  List<Map<String, String>> getVisibleList() {
    List<Map<String, String>> list =
    filteredList.isNotEmpty ? filteredList : originalList;

    if (selectedCategory == PodcastCategory.all) return list;

    final cat = selectedCategory == PodcastCategory.deen ? "deen" : "dunya";

    return list.where((p) => p['category'] == cat).toList();
  }

  /// ===============================
  /// SEARCH
  /// ===============================
  void search(String query) {
    final q = normalizeArabic(query.toLowerCase());

    if (q.isEmpty) {
      filteredList = [];
      emit(PodcastFilterState());
      return;
    }

    filteredList = originalList.where((p) {
      final title = normalizeArabic(p['title']!.toLowerCase());
      return title.contains(q);
    }).toList();

    emit(PodcastFilterState());
  }

  /// ===============================
  /// EPISODES
  /// ===============================
  List<Episode> episodes = [];
  List<Episode> filteredEpisodes = [];

  Future<void> fetchPlaylist(String playlistUrlOrId) async {
    emit(PodcastLoading());
    try {
      final playlistId =
          YouTubeService.extractPlaylistId(playlistUrlOrId) ??
              playlistUrlOrId;

      final items = await yt.fetchPlaylistItems(
        playlistId: playlistId,
      );

      final videoIds =
      items.map((e) => e['videoId'] as String).toList();

      final contents =
      await yt.fetchVideosContentDetails(videoIds: videoIds);

      episodes = items.map((it) {
        final vid = it['videoId'] as String;
        final content = contents[vid] as Map<String, dynamic>?;
        return Episode.fromMap(snippet: it, contentMap: content);
      }).toList();

      emit(PodcastLoaded(playlistId: playlistId, episodes: episodes));
    } catch (e) {
      emit(PodcastError(e.toString()));
    }
  }

  void searchEpisode(String query) {
    final q = normalizeArabic(query.toLowerCase());

    if (q.isEmpty) {
      filteredEpisodes = episodes;
      emit(PodcastFilterState());
      return;
    }

    filteredEpisodes = episodes.where((episode) {
      final title = normalizeArabic(episode.title.toLowerCase());
      return title.contains(q);
    }).toList();

    emit(PodcastFilterState());
  }

  /// ===============================
  /// UTILS
  /// ===============================
  String normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[أإآا]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), '')
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '')
        .trim();
  }
}