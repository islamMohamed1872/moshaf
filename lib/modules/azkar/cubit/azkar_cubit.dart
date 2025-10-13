import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import '../../../components/audio_service.dart';
import '../../../components/cache_helper.dart';
import '../../../components/const.dart';
import 'azkar_states.dart';

class AzkarCubit extends Cubit<AzkarStates> {
  AzkarCubit() : super(AzkarInitialState());
  static AzkarCubit get(context) => BlocProvider.of(context);

  final Dio _dio = Dio();
  final player = AudioServices().player;

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
      azkar[0]['array'] = azkarSabah['array'];
      azkar[0]['category'] = azkarSabah['category'];
      azkar.insert(1, azkarMasaa);

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
      azkar[0]['array'] = azkarSabah['array'];
      azkar[0]['category'] = azkarSabah['category'];
      azkar.insert(1, azkarMasaa);

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
      print(1);
      // toggle if same url
      if (playingUrl == url) {
        // if currently playing -> pause; if paused -> resume
        if (player.playing) {
          print(2);
          await player.pause();
        } else {
          print(3);
          await player.play();
        }
        emit(AzkarPlayChangedState());
        print(4);
        return;
      }

      // new audio: stop previous, set new url, play
      print(5);
      await player.stop();
      playingUrl = url;
      final source =  AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: 'اذكار',
          title: 'اذكار',
          artUri: Uri.parse(
              'http://osoulfinancial.com/wp-content/uploads/2025/10/WhatsApp%20Image%202025-10-06%20at%2011.32.38.jpeg'),
        ),
      );

      print(6);
      await player.setAudioSource(source);
      player.play();
      print(7);

      // emit play change and listen to finished state
      emit(AzkarPlayChangedState());
      print(8);

      player.playerStateStream.listen((state) {
        // update UI on changes
        emit(AzkarPlayChangedState());
        // if completed, clear playingUrl
        if (state.processingState == ProcessingState.completed) {
          print(9);
          playingUrl = null;
          emit(AzkarPlayChangedState());
        }
      });
    } catch (e) {
      playingUrl = null;
      print(10);
      print(e);
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
  void decrementCount(Map<String, dynamic> item) {
    int current = (item['count'] ?? 0) as int;
    if (current > 0) {
      item['count'] = current - 1;
      emit(AzkarLoadedState());
    }
    if(item['count']==0&&Platform.isAndroid){
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
  }
}
