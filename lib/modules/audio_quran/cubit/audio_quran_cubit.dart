import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moshaf/modules/audio_quran/cubit/audio_quran_states.dart';

import '../../../components/audio_service.dart';
import '../../../components/const.dart';

class AudioQuranCubit extends Cubit<AudioQuranStates>{
  AudioQuranCubit():super(AudioQuranInitialState());
  static AudioQuranCubit get(context)=> BlocProvider.of(context);
  bool validSearch = false;
  bool errorSearch = false;
  var searchController = TextEditingController();
  final player = AudioServices().player;
  List searchedSorahNumber = [];
  int searchedPageNumber = 0;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  Duration remaining = Duration.zero;
  int sorahNumber = 0 ;

  Timer? _searchDebounce;
  bool get canGoNext => sorahNumber < 114;
  bool get canGoPrev => sorahNumber > 1;

  void _resetSurahState() {
    duration = Duration.zero;
    position = Duration.zero;
    isPlaying = false;
    isPaused = true;
    player.stop();
    emit(AudioQuranInitialState());
  }
  void seekTo(Duration pos) {
    player.seek(pos);
  }
  void nextSurah() {
    if (!canGoNext) return;
    sorahNumber++;
    _resetSurahState();
    play();
  }
  void prevSurah() {
    if (!canGoPrev) return;
    sorahNumber--;
    _resetSurahState();
    play();
  }

  void getSorahNumber(String name) {
    // Cancel any ongoing debounce
    _searchDebounce?.cancel();

    // If field is empty, reset instantly
    if (name.trim().isEmpty) {
      searchedSorahNumber.clear();
      validSearch = false;
      errorSearch = false;
      emit(SearchedSorahNumber());
      return;
    }

    // Start debounce
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final currentText = searchController.text.trim(); // always get latest value
      searchedSorahNumber.clear();

      if (currentText.isEmpty) {
        validSearch = false;
        errorSearch = false;
        emit(SearchedSorahNumber());
        return;
      }

      // Search for matches where key starts with the typed value
      final matches = quranMap.entries
          .where((entry) => entry.key.contains(currentText))
          .map((entry) => entry.value)
          .toList();
      // print(matches);
      if (matches.isNotEmpty) {
        searchedSorahNumber.addAll(matches);
        validSearch = true;
        errorSearch = false;
      } else {
        validSearch = false;
        errorSearch = true;
      }

      emit(SearchedSorahNumber());
    });
  }
  int homeCount = 20;
  void loadMore() {
    if (homeCount + 10 <= 114) {
      homeCount += 20;
    } else {
      homeCount = 114;
    }
    emit(IncreaseHomeCountSuccessState());
  }

  // final player = AudioPlayer();
  String formatTime(Duration duration) {
    String twoDegits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDegits(duration.inHours);
    final minutes = twoDegits(duration.inMinutes.remainder(60));
    final secondes = twoDegits(duration.inSeconds.remainder(60));
    return [
      if (duration.inHours > 0) hours,
      minutes,
      secondes,
    ].join(":");
  }

  bool isPlaying = false;
  bool isPaused = true;
  String selecteShiekh = "مشاري راشد العفاسي";
  String url = "";
  final shiekhList = [
    "أحمد العجمي",
    "خالد الجليل",
    "خالد القحطاني",
    "عبد الباسط عبد الصمد",
    "عبد الرحمن السديس",
    "محمود علي البنا",
    "محمد صديق المنشاوي",
    "مشاري راشد العفاسي",
    "ناصر القطامي",
    "ياسر الدوسري"
  ];
  final Map<String, String> sheikhEditionCodes = {
    "مشاري راشد العفاسي": "ar.alafasy",
    "عبد الباسط عبد الصمد": "ar.abdulbasitmujawwad", // or murattal
    "محمود علي البنا": "ar.mahmoudalialbanna",
    "محمد صديق المنشاوي": "ar.muhammadsiddiqalminshawimujawwad",
    "عبد الرحمن السديس": "ar.sudaisshuraymnaeemsultan",
    "أحمد العجمي": "ar.ahmedalajmi",
    "خالد القحطاني": "ar.khaledalqahtani",
    "ناصر القطامي": "ar.nasseralqatami",
    "ياسر الدوسري": "ar.yasseraldossari",
    "خالد الجليل":  "ar.khalidaljalil"
  };
  String getQuranApiUrl() {
    final edition = sheikhEditionCodes[selecteShiekh];
    if (edition == null) {
      throw Exception("Edition code not found for $selecteShiekh");
    }
    return "https://cdn.islamic.network/quran/audio-surah/128/$edition/$sorahNumber.mp3";
  }

  Future<void> play() async {
    emit(GetDataLoadingState());
    String url = getQuranApiUrl();
    try {
      if (!isPlaying) {
        final fileInfo = await DefaultCacheManager().getFileFromCache(url);
        final source = fileInfo != null && fileInfo.file.existsSync()
            ? AudioSource.uri(
          Uri.file(fileInfo.file.path),
          tag: MediaItem(
            id: '$sorahNumber',
            album: selecteShiekh,
            title: quranMap.entries
                .firstWhere((e) => e.value == sorahNumber)
                .key,
            artUri: Uri.parse(
                'https://osoulfinancial.com/wp-content/uploads/2025/10/WhatsApp%20Image%202025-10-06%20at%2011.32.38.jpeg'),
          ),
        )
            : AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: '$sorahNumber',
            album: selecteShiekh,
            title: quranMap.entries
                .firstWhere((e) => e.value == sorahNumber)
                .key,
            artUri: Uri.parse(
                'https://osoulfinancial.com/wp-content/uploads/2025/10/WhatsApp%20Image%202025-10-06%20at%2011.32.38.jpeg'),
          ),
        );
        print('URL: $url');
        print('Is HTTP: ${url.startsWith('http:')}');
        print('Cache file exists: ${fileInfo?.file.existsSync()}');
        try {
          await player.setAudioSource(source);
          print("✅ Audio source set successfully");
          player.play();
          isPlaying = true;
          isPaused = false;
        } catch (e, s) {
          print("❌ Player error: $e");
          print(s);
        }


        player.durationStream.listen((d) {
          if (d != null) {
            duration = d;
            emit(ChangeSorahDuration());
          }
        });

        player.positionStream.listen((p) {
          position = p;
          emit(GetPositionState());
        });

        emit(GetDataSuccessState());
      } else if (isPlaying && !isPaused) {
        player.pause();
        isPaused = true;

      } else if (isPaused) {
        player.play();
        isPaused = false;
      }

      emit(GetDataSuccessState());
    } catch (e) {
      print(e);
      emit(GetDataErrorState());
    }
  }
  void changeSelectedShiekh(String? value){
    selecteShiekh = value!;
    emit(ChangeSelectedShiekhState());
  }



}