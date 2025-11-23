import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/azkar.dart';
import 'package:moshaf/controllers/prayer_times/prayer_times_cubit.dart';
import 'package:vibration/vibration.dart';
import '../../components/audio_service.dart';
import '../../components/cache_helper.dart';
import '../../components/const.dart';
import '../../views/azkar/one_pray_screen.dart';
import '../../views/azkar/zekr_screen.dart';
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
    if (item['original_count'] == null) item["original_count"] = item['count'];
    int current = (item['count'] ?? 0) as int;
    if (current > 0) {
      item['count'] = current - 1;
      emit(AzkarLoadedState());
    }
    if(item['count']==0&&Platform.isAndroid){
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
  }

  void resetCount(Map<String, dynamic> item) {
    if (item['original_count'] != null) item['count'] = item['original_count'];
    emit(AzkarLoadedState());
  }


  final random = Random();
  String getRandomZekr(List<dynamic> list) {
    final randomItem = list[random.nextInt(list.length)];
    return randomItem['zekr'] ?? ''; // Return the zekr text safely
  }
  String randomZekr = "";
  String zekrCategory = "";
  void getZekrBasedOnTime(context)async {
    DateTime now = DateTime.now();
    // Example lists
    final azkarAlAdhan = AzkarConstants.azkarAlAdhan;
    final azkarBaadAlsalah = AzkarConstants.azkarBaadAlsalah;
    final azkarSabah = AzkarConstants.azkarSabah;
    final azkarMasaa = AzkarConstants.azkarMasaa;
    final azkarMotafareqa = AzkarConstants.azkarMotafareqa;
    final prayerTimes = PrayerTimesCubit.get(context).prayerTimes;
    if(prayerTimes.isEmpty){
     await PrayerTimesCubit.get(context).fetchPrayerTimesNoInternet();
    }

    // 🔹 1. Check if just after any prayer time
    for (var entry in prayerTimes.entries) {
      final prayerTime = entry.value;
      final difference = now.difference(prayerTime).inMinutes;

      if (difference >= 0 && difference <= 2) {
        print(getRandomZekr(azkarAlAdhan['azkar']));
        randomZekr = getRandomZekr(azkarAlAdhan['azkar']);
        zekrCategory = azkarAlAdhan['category'];
        emit(GetZekrBasedOnTimeState());
        return;
      } else if (difference > 2 && difference <= 5) {
        randomZekr = getRandomZekr(azkarBaadAlsalah['azkar']);
        zekrCategory = azkarBaadAlsalah['category'];
        emit(GetZekrBasedOnTimeState());
        return;
      }
    }

    // 🔹 2. Morning (after Fajr until Shorouq)
    if (now.isAfter(prayerTimes["الفجر"]!) && now.isBefore(prayerTimes["الشروق"]!)) {
      randomZekr = getRandomZekr(azkarSabah['azkar']);
      zekrCategory = azkarSabah['category'];
      emit(GetZekrBasedOnTimeState());
      return;
    }

    // 🔹 3. Evening (after Maghrib until Isha)
    if (now.isAfter(prayerTimes["المغرب"]!) && now.isBefore(prayerTimes["العشاء"]!)) {
      randomZekr = getRandomZekr(azkarMasaa['azkar']);
      zekrCategory = azkarMasaa['category'];
      emit(GetZekrBasedOnTimeState());
      return;
    }

    // 🔹 4. Otherwise
    randomZekr = getRandomZekr(azkarMotafareqa['azkar']);
    zekrCategory = azkarMotafareqa['category'];
    emit(GetZekrBasedOnTimeState());
    return;
  }
  void navigateToRelatedAzkarScreen( context, String category) {
    final categories = {
      "أذكار الصباح": AzkarConstants.azkarSabah,
      "أذكار المساء": AzkarConstants.azkarMasaa,
      "أذكار بعد الصلاة": AzkarConstants.azkarBaadAlsalah,
      "أذكار الأذان": AzkarConstants.azkarAlAdhan,
      "أذكار متفرقة": AzkarConstants.azkarMotafareqa,
      "أذكار الاستيقاظ": AzkarConstants.azkarAlIstiqaz,
      "أذكار النوم": AzkarConstants.azkarAlNawm,
      "أذكار المسجد": AzkarConstants.azkarAlMasjid,
      "أذكار الطعام": AzkarConstants.azkarAlTaam,
      "أذكار الوضوء": AzkarConstants.azkarAlWudu,
      "أذكار الحج والعمرة": AzkarConstants.azkarAlHajjWalUmrah,
      "أذكار المنزل": AzkarConstants.azkarAlManzil,
    };

    final selected = categories[category];
    if (selected != null) {
      navigateTo(context, ZekrScreen(title: category, items: selected));
    }
  }

  String randomDoaa = "";
  String doaaCategory = "";
  void getRandomDuaa() {
    List doaa = [
      AzkarConstants.jawameDoaa,
      AzkarConstants.adeyahNabaweyah,
      AzkarConstants.adeyaQuranya,
    ];
    final randomDoaaListIndex = random.nextInt(doaa.length);

    if (doaa[randomDoaaListIndex]["azkar"].isEmpty) return;
    final randomIndex = random.nextInt(doaa[randomDoaaListIndex]["azkar"].length);
    randomDoaa= doaa[randomDoaaListIndex]["azkar"][randomIndex]["zekr"];
    doaaCategory= doaa[randomDoaaListIndex]["category"];
    emit(GetRandomDuaa());
  }

  void navigateToRelatedDoaaScreen( context, String category,bool isDark) {
    final categories = {
      "جوامع الدعاء": AzkarConstants.jawameDoaa,
      "أدعية نبوية": AzkarConstants.adeyahNabaweyah,
      "أدعية قرآنية": AzkarConstants.adeyaQuranya,
    };

    final selected = categories[category];
    if (selected != null) {
      navigateTo(context, OnePrayScreen(title: category, items: selected,isDark: isDark,));
    }
  }

  bool isSwipeView = false;

  void toggleViewMode() {
    isSwipeView = !isSwipeView;
    emit(ChangeViewModeState());
  }

  PageController pageController = PageController();

  int currentSwipeIndex = 0;

  void changeSwipeIndex(int idx) {
    currentSwipeIndex = idx;
    emit(ChangeSwipeIndexState()); // create state class
  }
}
