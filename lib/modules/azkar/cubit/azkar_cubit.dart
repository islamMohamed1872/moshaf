import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../components/cache_helper.dart';
import 'azkar_states.dart';

class AzkarCubit extends Cubit<AzkarStates> {
  AzkarCubit() : super(AzkarInitialState());
  static AzkarCubit get(context) => BlocProvider.of(context);

  final Dio _dio = Dio();
  final AudioPlayer player = AudioPlayer();

  // Data
  List<Map<String, dynamic>> azkar = [];
  List<dynamic> filteredAzkar = [];

  // playback state
  String? playingUrl; // full url currently playing
  bool get isPlaying => player.playing;
  bool get isPaused => !player.playing && player.processingState == ProcessingState.ready;

  // SOURCE - JSON + audio served from the GitHub repo via jsDelivr CDN
  // You can swap this base to your own hosting easily.
  static const String _ghBase = 'https://cdn.jsdelivr.net/gh/rn0x/Adhkar-json';
  static const String jsonUrl = '$_ghBase/adhkar.json';

  /// load JSON (call once, e.g. in init)
  Future<void> loadAzkar() async {
    if(azkar.isNotEmpty) return;
    emit(AzkarLoadingState());
    try {
      final resp = await _dio.get(jsonUrl);
      final data = resp.data;
      // repo returns a top-level array of categories
      if (data is List) {
        azkar = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('azkar')) {
        azkar = List<Map<String, dynamic>>.from(data['azkar']);
      } else {
        // fallback: try to parse as map of categories
        throw Exception('Unexpected JSON format');
      }

      // optional: normalize audio fields or other cleanup here
      filteredAzkar = List.from(azkar);
      // Save to cache for offline use
      await CacheHelper.saveMap(
        key: 'cached_azkar',
        myMap: {'data': azkar}, // wrap list in a map so saveMap can encode it
      );
      emit(AzkarLoadedState());
    } catch (e) {
      loadCachedAzkar();
      emit(AzkarErrorState(e.toString()));
    }
  }
  Future<bool> loadCachedAzkar() async {
    final cached = await CacheHelper.getMap(key: 'cached_azkar');
    if (cached != null && cached['data'] is List) {
      azkar = List<Map<String, dynamic>>.from(cached['data']);
      filteredAzkar = List.from(azkar);
      emit(AzkarLoadedState());
      return true;
    }
    return false;
  }

  void searchAzkar(String query) {
    if (query.trim().isEmpty) {
      filteredAzkar = List.from(azkar);
    } else {
      filteredAzkar = azkar.where((cat) {
        final title = (cat['category'] ?? cat['title'] ?? '').toString();
        return title.contains(query) ||
            (cat['array'] as List).any((item) =>
                (item['text'] ?? '').toString().contains(query));
      }).toList();
    }
    emit(AzkarLoadedState());
  }

  /// Build a full URL for an audio path coming from the JSON.
  /// JSON often contains "/audio/75.mp3" or "audio/75.mp3".
  String fullAudioUrl(String relativePath) {
    if (relativePath.trim().isEmpty) return relativePath;
    if (relativePath.startsWith('http')) return relativePath;
    final rp = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    return '$_ghBase/$rp';
  }

  /// Play/pause/toggle a given relative audio path.
  /// categoryIndex and itemId optional - useful for UI highlighting.
  void refresh(){
    emit(AzkarLoadedState());
  }
  Future<void> playAudio(String relativePath) async {
    emit(AzkarPlayChangedState());
    final url = fullAudioUrl(relativePath);
    try {
      // toggle if same url
      if (playingUrl == url) {
        // if currently playing -> pause; if paused -> resume
        if (player.playing) {
          await player.pause();
        } else {
          await player.play();
        }
        emit(AzkarPlayChangedState());
        return;
      }

      // new audio: stop previous, set new url, play
      await player.stop();
      playingUrl = url;

      await player.setUrl(url);
      await player.play();

      // emit play change and listen to finished state
      isPlaying;
      isPaused;
      emit(AzkarPlayChangedState());

      player.playerStateStream.listen((state) {
        // update UI on changes
        emit(AzkarPlayChangedState());
        // if completed, clear playingUrl
        if (state.processingState == ProcessingState.completed) {
          playingUrl = null;
          emit(AzkarPlayChangedState());
        }
      });
    } catch (e) {
      playingUrl = null;
      emit(AzkarErrorState('Audio error: $e'));
    }
  }

  Future<void> stopAudio() async {
    await player.stop();
    playingUrl = null;
    emit(AzkarPlayChangedState());
  }

  @override
  Future<void> close() {
    player.dispose();
    return super.close();
  }
}
