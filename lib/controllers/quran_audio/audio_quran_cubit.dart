import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moshaf/constants/app_const.dart';
import 'package:moshaf/controllers/quran_audio/audio_quran_states.dart';
import 'package:quran/quran.dart' as quran;

import '../../components/audio_service.dart';
import '../../components/const.dart';
import '../../models/playlist_model.dart';
import '../../models/reciter_model.dart';
import '../../services/mp3quran_service.dart';
import '../../views/quran/widgets/ReciterPickerSheet.dart';

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


  final Mp3QuranService _service = Mp3QuranService();

  List<Reciter> reciters = [];
  List<Reciter> visibleReciters = [];
  Reciter? selectedReciter;
  Moshaf? selectedMoshaf;

  // Simplified state management - only track playing state
  PlayerState _playerState = PlayerState.stopped;

  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused => _playerState == PlayerState.paused;
  bool get isStopped => _playerState == PlayerState.stopped;

  Future<void> loadReciters({String lang = 'ar'}) async {
    emit(GetDataLoadingState());
    try {
      reciters = await _service.getReciters(language: lang);
      visibleReciters = List.from(reciters);


      // default selection
      selectedReciter = reciters.first;
      selectedMoshaf = selectedReciter!.moshaf.first;

      emit(GetDataSuccessState());
    } catch (e) {
      emit(GetDataErrorState());
    }
  }

  String normalizeArabicLetter(String text) {
    if (text.isEmpty) return '#';

    final first = text.characters.first;

    switch (first) {
      case 'أ':
      case 'إ':
      case 'آ':
        return 'ا';
      default:
        return first;
    }
  }

  Map<String, List<Reciter>> getGroupedReciters() {
    final Map<String, List<Reciter>> grouped = {
      for (final letter in AppConstants.arabicAlphabet) letter: []
    };

    for (final reciter in visibleReciters) {
      final letter = normalizeArabicLetter(reciter.name);
      if (grouped.containsKey(letter)) {
        grouped[letter]!.add(reciter);
      }
    }

    // Remove empty sections
    grouped.removeWhere((key, value) => value.isEmpty);

    return grouped;
  }

  void searchSheikh(String query) {
    final q = normalizeArabic(query);

    if (q.isEmpty) {
      visibleReciters = List.from(reciters);
    } else {
      visibleReciters = reciters.where((r) {
        return normalizeArabic(r.name).contains(q);
      }).toList();
    }

    emit(GetDataSuccessState());
  }
  String normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[أإآا]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '')
        .trim();
  }

  void openReciterSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ReciterPickerSheet(),
    );
  }


  void changeReciter(Reciter r) {
    selectedReciter = r;
    selectedMoshaf = r.moshaf.first;
    stop();
    emit(ChangeSelectedShiekhState());
  }

  String getAudioUrl() {
    if (selectedMoshaf == null) {
      throw Exception("No moshaf selected");
    }

    final server = selectedMoshaf!.server;
    final surah = sorahNumber.toString().padLeft(3, '0');

    return '$server$surah.mp3';
  }


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
    player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        await player.stop();
        await player.seek(Duration.zero);

        // ✅ Check if playing from playlist
        if (_currentPlaylistQueue.isNotEmpty) {
          _currentQueueIndex++;
          await _playNextInQueue();
        } else {
          updatePlayerState(PlayerState.stopped);
          position = Duration.zero;
          emit(GetDataSuccessState());
        }
      }
    });
  }

  MediaItem _mediaItem() {
    return MediaItem(
      id: '$sorahNumber',
      album: selectedReciter?.name ?? '',
      title: quranMap.entries
          .firstWhere((e) => e.value == sorahNumber)
          .key,
      artUri: Uri.parse(
        'https://osoulfinancial.com/wp-content/uploads/2025/10/WhatsApp%20Image%202025-10-06%20at%2011.32.38.jpeg',
      ),
    );
  }

  Future<bool> _urlExists(String url) async {
    try {
      final response = await HttpClient()
          .headUrl(Uri.parse(url))
          .then((req) => req.close());

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _handleAudioNotAvailable() {
    stop();
    emit(GetDataErrorState());

    // Optional: show toast/snackbar
    Fluttertoast.showToast(msg: "هذا القارئ لا يملك هذه السورة");

  }


  Future<void> play() async {
    try {
      if (sorahNumber < 1 || selectedMoshaf == null) return;

      // ⏸ Pause
      if (isPlaying) {
        await player.pause();
        updatePlayerState(PlayerState.paused);
        return;
      }

      // ▶ Resume
      if (isPaused) {
        await player.play();
        updatePlayerState(PlayerState.playing);
        return;
      }

      emit(GetDataLoadingState());

      final url = getAudioUrl();
      final cache = DefaultCacheManager();

      // 🔍 Check URL availability first
      final exists = await _urlExists(url);
      if (!exists) {
        _handleAudioNotAvailable();
        return;
      }

      // 🔍 Check cache
      final fileInfo = await cache.getFileFromCache(url);

      late AudioSource source;

      if (fileInfo != null && fileInfo.file.existsSync()) {
        source = AudioSource.uri(
          Uri.file(fileInfo.file.path),
          tag: _mediaItem(),
        );
      } else {
        source = AudioSource.uri(
          Uri.parse(url),
          tag: _mediaItem(),
        );

        // ⬇ Cache in background (safe)
        cache.downloadFile(url).catchError((_) {});
      }

      await player.setAudioSource(source);
      await player.play();

      updatePlayerState(PlayerState.playing);
      emit(GetDataSuccessState());

    } catch (e, s) {
      debugPrint("❌ Audio error: $e");
      debugPrintStack(stackTrace: s);
      _handleAudioNotAvailable();
    }
  }


  void stop() async {
    await player.stop();
    await player.seek(Duration.zero);
    updatePlayerState(PlayerState.stopped);
    position = Duration.zero;
    emit(AudioQuranStoppedState());
  }

  List<PlaylistItem> _currentPlaylistQueue = [];
  int _currentQueueIndex = 0;

// ✅ Play a single playlist item with range
  Future<void> playPlaylistItem(PlaylistItem item) async {
    try {
      sorahNumber = item.surah;

      // Set queue with single item
      _currentPlaylistQueue = [item];
      _currentQueueIndex = 0;

      emit(GetDataLoadingState());

      final url = getAudioUrl();
      final cache = DefaultCacheManager();

      // Check URL availability
      final exists = await _urlExists(url);
      if (!exists) {
        _handleAudioNotAvailable();
        return;
      }

      // Get cache or stream
      final fileInfo = await cache.getFileFromCache(url);

      late AudioSource source;

      if (fileInfo != null && fileInfo.file.existsSync()) {
        source = AudioSource.uri(
          Uri.file(fileInfo.file.path),
          tag: _mediaItem(),
        );
      } else {
        source = AudioSource.uri(
          Uri.parse(url),
          tag: _mediaItem(),
        );
        cache.downloadFile(url).catchError((_) {});
      }

      await player.setAudioSource(source);

      // ✅ Seek to start verse if not 1
      if (item.startVerse > 1) {
        // Estimate position based on verse (rough calculation)
        final estimatedDuration = duration.inSeconds;
        final versePosition = (estimatedDuration * (item.startVerse - 1)) ~/
            quran.getVerseCount(item.surah);

        await player.seek(Duration(seconds: versePosition));
      }

      await player.play();
      updatePlayerState(PlayerState.playing);
      emit(GetDataSuccessState());

    } catch (e, s) {
      debugPrint("❌ Playlist item error: $e");
      debugPrintStack(stackTrace: s);
      _handleAudioNotAvailable();
    }
  }

// ✅ Play entire playlist sequentially
  Future<void> playPlaylist(Playlist playlist) async {
    try {
      if (playlist.items.isEmpty) {
        Fluttertoast.showToast(msg: "القائمة فارغة");
        return;
      }

      _currentPlaylistQueue = List.from(playlist.items);
      _currentQueueIndex = 0;

      emit(PlaylistPlayingState(playlist.name));
      await _playNextInQueue();

    } catch (e) {
      debugPrint("❌ Playlist error: $e");
      Fluttertoast.showToast(msg: "خطأ في تشغيل القائمة");
    }
  }

// ✅ Internal: Play next item in playlist queue
  Future<void> _playNextInQueue() async {
    try {
      if (_currentQueueIndex >= _currentPlaylistQueue.length) {
        // Playlist finished
        stop();
        Fluttertoast.showToast(msg: "انتهت القائمة");
        emit(PlaylistFinishedState());
        return;
      }

      final currentItem = _currentPlaylistQueue[_currentQueueIndex];
      sorahNumber = currentItem.surah;

      emit(GetDataLoadingState());

      final url = getAudioUrl();
      final cache = DefaultCacheManager();

      final exists = await _urlExists(url);
      if (!exists) {
        _currentQueueIndex++;
        await _playNextInQueue(); // Skip to next
        return;
      }

      final fileInfo = await cache.getFileFromCache(url);

      late AudioSource source;
      if (fileInfo != null && fileInfo.file.existsSync()) {
        source = AudioSource.uri(
          Uri.file(fileInfo.file.path),
          tag: _mediaItem(),
        );
      } else {
        source = AudioSource.uri(
          Uri.parse(url),
          tag: _mediaItem(),
        );
        cache.downloadFile(url).catchError((_) {});
      }

      await player.setAudioSource(source);

      // Seek to start verse
      if (currentItem.startVerse > 1) {
        await Future.delayed(const Duration(milliseconds: 500));
        await player.seek(Duration(seconds:
        (duration.inSeconds * (currentItem.startVerse - 1)) ~/
            quran.getVerseCount(currentItem.surah)
        ));
      }

      await player.play();
      updatePlayerState(PlayerState.playing);
      emit(GetDataSuccessState());

    } catch (e) {
      debugPrint("❌ Queue error: $e");
      _currentQueueIndex++;
      await _playNextInQueue();
    }
  }

// ✅ Skip to next playlist item
  void nextPlaylistItem() {
    if (_currentPlaylistQueue.isEmpty) {
      nextSurah();
      return;
    }

    _currentQueueIndex++;
    _playNextInQueue();
  }

// ✅ Skip to previous playlist item
  void prevPlaylistItem() {
    if (_currentPlaylistQueue.isEmpty) {
      prevSurah();
      return;
    }

    if (_currentQueueIndex > 0) {
      _currentQueueIndex--;
      _playNextInQueue();
    }
  }


}

// Add this enum for better state management
enum PlayerState {
  playing,
  paused,
  stopped,
}

