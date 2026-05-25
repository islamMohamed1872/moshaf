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
import '../../components/cache_helper.dart';
import '../../components/const.dart';
import '../../models/playlist_model.dart';
import '../../models/reciter_model.dart';
import '../../services/mp3quran_service.dart';
import '../../views/quran/widgets/ReciterPickerSheet.dart';

// ── Repeat mode ────────────────────────────────────────────────────────────────
enum RepeatMode { none, surah, range }

// ── Player state (renamed to avoid collision with just_audio) ─────────────────
enum PlayerState { playing, paused, stopped }

class AudioQuranCubit extends Cubit<AudioQuranStates> {
  AudioQuranCubit() : super(AudioQuranInitialState()) {
    _setupListeners();
  }

  static AudioQuranCubit get(context) => BlocProvider.of(context);

  // ── core ───────────────────────────────────────────────────────────────────
  bool validSearch = false;
  bool errorSearch = false;
  var searchController = TextEditingController();
  final player = AudioServices().player;
  List searchedSorahNumber = [];
  int searchedPageNumber = 0;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  int sorahNumber = 0;

  Timer? _searchDebounce;
  bool get canGoNext => sorahNumber < 114;
  bool get canGoPrev => sorahNumber > 1;

  final Mp3QuranService _service = Mp3QuranService();
  List<Reciter> reciters = [];
  List<Reciter> visibleReciters = [];
  Reciter? selectedReciter;
  Moshaf? selectedMoshaf;

  // ── playback state ─────────────────────────────────────────────────────────
  PlayerState _playerState = PlayerState.stopped;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isPaused  => _playerState == PlayerState.paused;
  bool get isStopped => _playerState == PlayerState.stopped;

  // ── repeat ─────────────────────────────────────────────────────────────────
  RepeatMode repeatMode = RepeatMode.none;
  int repeatStartVerse = 1;
  int repeatEndVerse   = 1;
  bool _isRangeLooping = false;   // true while verse-by-verse range loop is active

  void setRepeatMode(RepeatMode mode) {
    if (mode != RepeatMode.range) {
      _isRangeLooping = false;
    }
    repeatMode = mode;
    emit(RepeatToggledState());
  }

  void setRepeatRange({required int start, required int end}) {
    repeatStartVerse = start;
    repeatEndVerse   = end;
    emit(SetRepeatRangeState());
  }

  /// Plays [repeatStartVerse]–[repeatEndVerse] verse-by-verse and loops
  /// until [stopRangeLoop] is called.
  Future<void> startRangeLoop() async {
    if (sorahNumber < 1) return;

    _isRangeLooping = true;
    repeatMode = RepeatMode.range;
    emit(RepeatToggledState());
    emit(GetDataLoadingState());

    while (_isRangeLooping) {
      for (int verse = repeatStartVerse;
      verse <= repeatEndVerse && _isRangeLooping;
      verse++) {
        final url = quran.getAudioURLByVerse(
          sorahNumber, verse, "ar.abdulbasitmurattal",
        );
        try {
          await player.setAudioSource(
            AudioSource.uri(
              Uri.parse(url),
              tag: MediaItem(
                id: '$sorahNumber:$verse',
                album: 'Quran',
                title:
                'سورة ${quran.getSurahNameArabic(sorahNumber)} - آية $verse',
                artist: 'عبد الباسط عبد الصمد',
              ),
            ),
          );

          await player.play();
          updatePlayerState(PlayerState.playing);
          emit(GetDataSuccessState());

          await player.processingStateStream.firstWhere(
                (s) =>
            s == ProcessingState.completed ||
                !_isRangeLooping,
          );
        } catch (e) {
          debugPrint('❌ Range loop error at verse $verse: $e');
          _isRangeLooping = false;
          break;
        }
      }
    }

    // loop ended – clean up
    updatePlayerState(PlayerState.stopped);
    position = Duration.zero;
    emit(AudioQuranStoppedState());
  }

  void stopRangeLoop() {
    _isRangeLooping = false;
    stop();
  }

  // ── reciter loading ────────────────────────────────────────────────────────
  Future<void> loadReciters({String lang = 'ar'}) async {
    emit(GetDataLoadingState());
    try {
      reciters       = await _service.getReciters(language: lang);
      visibleReciters = List.from(reciters);

      // restore last selected reciter from cache
      final savedId = await CacheHelper.getData(key: 'selected_reciter_id');
      if (savedId != null && reciters.isNotEmpty) {
        try {
          final found = reciters.firstWhere(
                (r) => r.id.toString() == savedId.toString(),
          );
          selectedReciter = found;
          selectedMoshaf  = found.moshaf.first;
        } catch (_) {
          selectedReciter = reciters.first;
          selectedMoshaf  = selectedReciter!.moshaf.first;
        }
      } else if (reciters.isNotEmpty) {
        selectedReciter = reciters.first;
        selectedMoshaf  = selectedReciter!.moshaf.first;
      }

      emit(GetDataSuccessState());
    } catch (e) {
      emit(GetDataErrorState());
    }
  }

  // ── reciter helpers ────────────────────────────────────────────────────────
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
      for (final letter in AppConstants.arabicAlphabet) letter: [],
    };
    for (final reciter in visibleReciters) {
      final letter = normalizeArabicLetter(reciter.name);
      if (grouped.containsKey(letter)) grouped[letter]!.add(reciter);
    }
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  void searchSheikh(String query) {
    final q = normalizeArabic(query);
    visibleReciters = q.isEmpty
        ? List.from(reciters)
        : reciters.where((r) => normalizeArabic(r.name).contains(q)).toList();
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ReciterPickerSheet(),
    );
  }

  /// Change reciter and persist the choice.
  void changeReciter(Reciter r) {
    selectedReciter = r;
    selectedMoshaf  = r.moshaf.first;
    // ✅ persist so next launch restores the selection
    CacheHelper.saveData(key: 'selected_reciter_id', value: r.id.toString());
    stop();
    emit(ChangeSelectedShiekhState());
  }

  String getAudioUrl() {
    if (selectedMoshaf == null) throw Exception("No moshaf selected");
    final server = selectedMoshaf!.server;
    final surah  = sorahNumber.toString().padLeft(3, '0');
    return '$server$surah.mp3';
  }

  // ── state helpers ──────────────────────────────────────────────────────────
  void updatePlayerState(PlayerState state) {
    _playerState = state;
    emit(PlayerStateChangedState());
  }

  void _resetSurahState() {
    duration = Duration.zero;
    position = Duration.zero;
    _isRangeLooping = false;
    updatePlayerState(PlayerState.stopped);
    player.stop();
    emit(AudioQuranInitialState());
  }

  void seekTo(Duration pos) async {
    updatePlayerState(PlayerState.paused);
    await player.pause();
    player.seek(pos);
    emit(SeekToState());
  }

  void nextSurah() {
    if (!canGoNext) return;
    sorahNumber++;
    _isRangeLooping = false;
    _resetSurahState();
  }

  void prevSurah() {
    if (!canGoPrev) return;
    sorahNumber--;
    _isRangeLooping = false;
    _resetSurahState();
  }

  // ── search ─────────────────────────────────────────────────────────────────
  void getSorahNumber(String name) {
    _searchDebounce?.cancel();
    if (name.trim().isEmpty) {
      searchedSorahNumber.clear();
      validSearch = errorSearch = false;
      emit(SearchedSorahNumber());
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final current = searchController.text.trim();
      searchedSorahNumber.clear();
      if (current.isEmpty) {
        validSearch = errorSearch = false;
        emit(SearchedSorahNumber());
        return;
      }
      final matches = quranMap.entries
          .where((e) => e.key.contains(current))
          .map((e) => e.value)
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
    homeCount = (homeCount + 20).clamp(0, 114);
    emit(IncreaseHomeCountSuccessState());
  }

  String formatTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return [if (d.inHours > 0) h, m, s].join(':');
  }

  // ── listeners ──────────────────────────────────────────────────────────────
  void _setupListeners() {
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

    player.playerStateStream.listen((ps) {
      if (ps.playing) {
        updatePlayerState(PlayerState.playing);
      } else if (ps.processingState == ProcessingState.buffering) {
        updatePlayerState(PlayerState.paused);
      }
    });

    // ✅ Single completion handler (removed duplicate)
    player.processingStateStream.listen((state) async {
      if (state != ProcessingState.completed) return;

      // Range loop manages its own completion — don't interfere
      if (_isRangeLooping) return;

      await player.stop();
      await player.seek(Duration.zero);

      if (_currentPlaylistQueue.isNotEmpty) {
        // playlist queue
        _currentQueueIndex++;
        await _playNextInQueue();
      } else if (repeatMode == RepeatMode.surah) {
        // repeat whole surah
        await player.seek(Duration.zero);
        await player.play();
        updatePlayerState(PlayerState.playing);
      } else {
        updatePlayerState(PlayerState.stopped);
        position = Duration.zero;
        emit(GetDataSuccessState());
      }
    });
  }

  // ── play ───────────────────────────────────────────────────────────────────
  MediaItem _mediaItem() => MediaItem(
    id: '$sorahNumber',
    album: selectedReciter?.name ?? '',
    title: quranMap.entries.firstWhere((e) => e.value == sorahNumber).key,
    artUri: Uri.parse(
      'https://osoulfinancial.com/wp-content/uploads/2025/10/'
          'WhatsApp%20Image%202025-10-06%20at%2011.32.38.jpeg',
    ),
  );

  Future<bool> _urlExists(String url) async {
    try {
      final res = await HttpClient()
          .headUrl(Uri.parse(url))
          .then((req) => req.close());
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _handleAudioNotAvailable() {
    stop();
    emit(GetDataErrorState());
    Fluttertoast.showToast(msg: "هذا القارئ لا يملك هذه السورة");
  }

  Future<void> play() async {
    try {
      if (sorahNumber < 1 || selectedMoshaf == null) return;

      // stop range loop if active
      if (_isRangeLooping) {
        stopRangeLoop();
        return;
      }

      if (isPlaying) {
        await player.pause();
        updatePlayerState(PlayerState.paused);
        return;
      }

      if (isPaused) {
        await player.play();
        updatePlayerState(PlayerState.playing);
        return;
      }

      emit(GetDataLoadingState());

      final url    = getAudioUrl();
      final exists = await _urlExists(url);
      if (!exists) { _handleAudioNotAvailable(); return; }

      final cache    = DefaultCacheManager();
      final fileInfo = await cache.getFileFromCache(url);

      late AudioSource source;
      if (fileInfo != null && fileInfo.file.existsSync()) {
        source = AudioSource.uri(Uri.file(fileInfo.file.path), tag: _mediaItem());
      } else {
        source = AudioSource.uri(Uri.parse(url), tag: _mediaItem());
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
    _isRangeLooping = false;
    await player.stop();
    await player.seek(Duration.zero);
    updatePlayerState(PlayerState.stopped);
    position = Duration.zero;
    emit(AudioQuranStoppedState());
  }

  // ── playlist ───────────────────────────────────────────────────────────────
  List<PlaylistItem> _currentPlaylistQueue = [];
  int _currentQueueIndex = 0;

  Future<void> playPlaylistItem(PlaylistItem item) async {
    try {
      sorahNumber = item.surah;
      _currentPlaylistQueue = [item];
      _currentQueueIndex    = 0;
      emit(GetDataLoadingState());

      final url    = getAudioUrl();
      final exists = await _urlExists(url);
      if (!exists) { _handleAudioNotAvailable(); return; }

      final cache    = DefaultCacheManager();
      final fileInfo = await cache.getFileFromCache(url);
      late AudioSource source;
      if (fileInfo != null && fileInfo.file.existsSync()) {
        source = AudioSource.uri(Uri.file(fileInfo.file.path), tag: _mediaItem());
      } else {
        source = AudioSource.uri(Uri.parse(url), tag: _mediaItem());
        cache.downloadFile(url).catchError((_) {});
      }

      await player.setAudioSource(source);
      if (item.startVerse > 1) {
        final pos =
            (duration.inSeconds * (item.startVerse - 1)) ~/
                quran.getVerseCount(item.surah);
        await player.seek(Duration(seconds: pos));
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

  Future<void> playPlaylist(Playlist playlist) async {
    try {
      if (playlist.items.isEmpty) {
        Fluttertoast.showToast(msg: "القائمة فارغة");
        return;
      }
      _currentPlaylistQueue = List.from(playlist.items);
      _currentQueueIndex    = 0;
      emit(PlaylistPlayingState(playlist.name));
      await _playNextInQueue();
    } catch (e) {
      debugPrint("❌ Playlist error: $e");
      Fluttertoast.showToast(msg: "خطأ في تشغيل القائمة");
    }
  }

  Future<void> _playNextInQueue() async {
    try {
      if (_currentQueueIndex >= _currentPlaylistQueue.length) {
        stop();
        Fluttertoast.showToast(msg: "انتهت القائمة");
        emit(PlaylistFinishedState());
        return;
      }
      final item   = _currentPlaylistQueue[_currentQueueIndex];
      sorahNumber  = item.surah;
      emit(GetDataLoadingState());

      final url    = getAudioUrl();
      final exists = await _urlExists(url);
      if (!exists) { _currentQueueIndex++; await _playNextInQueue(); return; }

      final cache    = DefaultCacheManager();
      final fileInfo = await cache.getFileFromCache(url);
      late AudioSource source;
      if (fileInfo != null && fileInfo.file.existsSync()) {
        source = AudioSource.uri(Uri.file(fileInfo.file.path), tag: _mediaItem());
      } else {
        source = AudioSource.uri(Uri.parse(url), tag: _mediaItem());
        cache.downloadFile(url).catchError((_) {});
      }

      await player.setAudioSource(source);
      if (item.startVerse > 1) {
        await Future.delayed(const Duration(milliseconds: 500));
        await player.seek(Duration(seconds:
        (duration.inSeconds * (item.startVerse - 1)) ~/
            quran.getVerseCount(item.surah)));
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

  void nextPlaylistItem() {
    if (_currentPlaylistQueue.isEmpty) { nextSurah(); return; }
    _currentQueueIndex++;
    _playNextInQueue();
  }

  void prevPlaylistItem() {
    if (_currentPlaylistQueue.isEmpty) { prevSurah(); return; }
    if (_currentQueueIndex > 0) { _currentQueueIndex--; _playNextInQueue(); }
  }
}