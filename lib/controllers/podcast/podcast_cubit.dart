// podcast_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/models/episode_model.dart';
import '../../services/youtube_services.dart';
import 'podcast_states.dart';

enum PodcastCategory { all, deen, dunya }
enum PodcastSort { none, newest, oldest }


class PodcastCubit extends Cubit<PodcastStates> {
  final YouTubeService yt;
  PodcastCubit({required this.yt}) : super(PodcastInitial());
  static PodcastCubit get(context) => BlocProvider.of(context);
   List originalList = [];
  List filteredList = [];

  void getPodcasts(){
    emit(GetPodcastsLoadingStates());
    FirebaseFirestore.instance.collection("videos").doc("podcasts").get().then((value) {
      originalList = value.data()!['data'];
      getVisibleList();
      emit(GetPodcastsSuccessStates());
    }).catchError((error){
      print(error);
      emit(GetPodcastsErrorStates(error.toString()));
    });
  }

  /// ===============================
  /// CATEGORY STATE
  /// ===============================
  PodcastCategory selectedCategory = PodcastCategory.all;
  PodcastSort selectedSort = PodcastSort.none;

  /// ===============================
  /// PUBLIC METHODS USED BY UI
  /// ===============================

  /// Called when user taps a chip
  void changeCategory(PodcastCategory category) {
    selectedCategory = category;
    getVisibleList();
    emit(PodcastFilterState());
  }
  void changeSort(PodcastSort sort) {
    selectedSort = sort;
    sortPodcasts();
    emit(PodcastFilterState());
  }

  /// Final visible list (category + search)
  void getVisibleList() {
    filteredList= List.from(originalList);

    if (selectedCategory == PodcastCategory.all) {
      emit(PodcastFilterState());
      return;
    }

      final cat = selectedCategory == PodcastCategory.deen ? "deen" : "dunya";

    filteredList =  filteredList.where((p) => p['category'] == cat).toList();
    emit(PodcastFilterState());
  }

  void sortPodcasts(){
    filteredList  =List.from(originalList);
    if (selectedSort == PodcastSort.none){
      emit(PodcastFilterState());
      return;
    }
    filteredList.sort((a, b) {
      final aDate = _parseDate(a['created_at']);
      final bDate = _parseDate(b['created_at']);
      return selectedSort == PodcastSort.newest
          ? bDate.compareTo(aDate)
          : aDate.compareTo(bDate);
    });
    emit(PodcastFilterState());

  }
  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime(0);

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime(0);
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime(0);
  }


  /// ===============================
  /// SEARCH
  /// ===============================
  void search(String query) {
    final q = normalizeArabic(query.toLowerCase());

    if (q.isEmpty) {
      filteredList = List.from(originalList);
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


  Future<void> submitSuggestion({
    required String url,
    required String name,
    required String note,
  }) async
  {
    emit(SuggestPodcastLoadingState());
    await FirebaseFirestore.instance.collection('suggestions').add({
      'url':       url,
      'name':      name,
      'note':      note,
      'createdAt': FieldValue.serverTimestamp(),
    }).then((onValue){
      print(onValue);
      emit(SuggestPodcastSuccessState());
    }).catchError((onError){
      print(onError);
      emit(SuggestPodcastErrorState());
    });
  }
}