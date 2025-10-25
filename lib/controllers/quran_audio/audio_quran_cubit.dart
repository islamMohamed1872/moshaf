import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moshaf/controllers/quran_audio/audio_quran_states.dart';

import '../../components/audio_service.dart';
import '../../components/const.dart';

class AudioQuranCubit extends Cubit<AudioQuranStates> {
  AudioQuranCubit() : super(AudioQuranInitialState()) {
    _setupListeners(); // Set up listeners once in constructor
  }

  static AudioQuranCubit get(context) => BlocProvider.of(context);
  bool validSearch = false;
  bool errorSearch = false;
  var searchController = TextEditingController();
  final player = AudioServices().player;
  List searchedSorahNumber = [];
  int searchedPageNumber = 0;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  Duration remaining = Duration.zero;
  int sorahNumber = 0;

  Timer? _searchDebounce;
  bool get canGoNext => sorahNumber < 114;
  bool get canGoPrev => sorahNumber > 1;

  // Simplified state management - only track playing state
  PlayerState _playerState = PlayerState.stopped;

  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;
  bool get isStopped => _playerState == PlayerState.stopped;

  void updatePlayerState(PlayerState state) {
    _playerState = state;
    emit(PlayerStateChangedState());
  }

  void _resetSurahState() {
    duration = Duration.zero;
    position = Duration.zero;
    updatePlayerState(PlayerState.stopped);
    player.stop();
    emit(AudioQuranInitialState());
  }

  void seekTo(Duration pos)async {
    updatePlayerState(PlayerState.paused);
    await player.pause();
    player.seek(pos);
    emit(SeekToState());
  }

  void nextSurah() {
    if (!canGoNext) return;
    sorahNumber++;
    _resetSurahState();
    // play();
  }

  void prevSurah() {
    if (!canGoPrev) return;
    sorahNumber--;
    _resetSurahState();
    // play();
  }

  void getSorahNumber(String name) {
    _searchDebounce?.cancel();

    if (name.trim().isEmpty) {
      searchedSorahNumber.clear();
      validSearch = false;
      errorSearch = false;
      emit(SearchedSorahNumber());
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final currentText = searchController.text.trim();
      searchedSorahNumber.clear();

      if (currentText.isEmpty) {
        validSearch = false;
        errorSearch = false;
        emit(SearchedSorahNumber());
        return;
      }

      final matches = quranMap.entries
          .where((entry) => entry.key.contains(currentText))
          .map((entry) => entry.value)
          .toList();

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
    "عبد الباسط عبد الصمد": "ar.abdulbasitmujawwad",
    "محمود علي البنا": "ar.mahmoudalialbanna",
    "محمد صديق المنشاوي": "ar.muhammadsiddiqalminshawimujawwad",
    "عبد الرحمن السديس": "ar.sudaisshuraymnaeemsultan",
    "أحمد العجمي": "ar.ahmedalajmi",
    "خالد القحطاني": "ar.khaledalqahtani",
    "ناصر القطامي": "ar.nasseralqatami",
    "ياسر الدوسري": "ar.yasseraldossari",
    "خالد الجليل": "ar.khalidaljalil"
  };

  String getQuranApiUrl() {
    final edition = sheikhEditionCodes[selecteShiekh];
    if (edition == null) {
      throw Exception("Edition code not found for $selecteShiekh");
    }
    if (selecteShiekh == "ياسر الدوسري") {
      return "https://server11.mp3quran.net/yasser/${sorahNumber.toString().padLeft(3, "0")}.mp3";
    }
    return "https://cdn.islamic.network/quran/audio-surah/128/$edition/$sorahNumber.mp3";
  }

  void _setupListeners() {
    // Set up listeners once in constructor
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

    player.playerStateStream.listen((playerState) {
      // Update internal state based on Just Audio's player state
      if (playerState.playing) {
        updatePlayerState(PlayerState.playing);
      } else if (playerState.processingState == ProcessingState.completed) {
        updatePlayerState(PlayerState.stopped);
        position = Duration.zero;
        emit(GetDataSuccessState());
      }
      else if (playerState.processingState == ProcessingState.buffering) {
        updatePlayerState(PlayerState.paused);
      }
    });

    player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        await player.stop();
        await player.seek(Duration.zero);
        updatePlayerState(PlayerState.stopped);
        position = Duration.zero;
        emit(GetDataSuccessState());
      }
    });
  }

  Future<void> play() async {
    try {
      // If we're already playing, pause
      if (isPlaying) {
        print("isPlaying");
        await player.pause();
        updatePlayerState(PlayerState.paused);
        emit(GetDataSuccessState());
        return;
      }

      // If we're paused, resume
      if (isPaused) {
        await player.play();
        updatePlayerState(PlayerState.playing);
        emit(GetDataSuccessState());
        return;
      }

      // If we're stopped, load and play new audio
      emit(GetDataLoadingState());
      String url = getQuranApiUrl();

      final fileInfo = await DefaultCacheManager().getFileFromCache(url);
      if(fileInfo== null){
        DefaultCacheManager().downloadFile(url);
      }
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
      await player.setAudioSource(source);
      print("✅ Audio source set successfully");

      player.play();
      updatePlayerState(PlayerState.playing);
      _setupListeners();
      emit(GetDataSuccessState());

    } catch (e, s) {
      print("❌ Player error: $e");
      print(s);
      updatePlayerState(PlayerState.stopped);
      emit(GetDataErrorState());
    }
  }

  void changeSelectedShiekh(String? value) {
    selecteShiekh = value!;
    stop();
    duration = Duration.zero;
    position = Duration.zero;
    emit(ChangeSelectedShiekhState());
  }

  void stop() async {
    await player.stop();
    await player.seek(Duration.zero);
    updatePlayerState(PlayerState.stopped);
    position = Duration.zero;
    emit(AudioQuranStoppedState());
  }
}

// Add this enum for better state management
enum PlayerState {
  playing,
  paused,
  stopped,
}

