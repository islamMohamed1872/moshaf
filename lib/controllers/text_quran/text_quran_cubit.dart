import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moshaf/controllers/text_quran/text_quran_states.dart';
import 'package:moshaf/network/dio_helper.dart';
import 'package:quran/quran.dart' as quran1;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:quran/quran.dart' as quran;
import '../../components/audio_service.dart';
import '../../components/cache_helper.dart';
import '../../components/const.dart';
import '../../models/sura.dart';

class TextQuranCubit extends Cubit<TextQuranStates>{
  TextQuranCubit():super(TextQuranInitialState());
  static TextQuranCubit get(context)=> BlocProvider.of(context);

  TextEditingController searchController = TextEditingController();


  final Set<String> _loadedFonts = {};

  Future<void> loadQuranFontCached(int pageNumber) async {
    emit(GetFontLoadingState());
    final fontName = "QCF_P${pageNumber.toString().padLeft(3, "0")}";

    // Don’t reload if already loaded
    if (_loadedFonts.contains(fontName)) return;

    final fontUrl =
        "https://cdn.jsdelivr.net/gh/islamMohamed1872/qcf-fonts/QCF2${pageNumber.toString().padLeft(3, "0")}.ttf";

    try {
      final file = await DefaultCacheManager().getSingleFile(fontUrl);
      final bytes = await file.readAsBytes();

      final loader = FontLoader(fontName);
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();

      _loadedFonts.add(fontName); // mark as loaded
      emit(GetFontSuccessState());
    } catch (e) {
      debugPrint("Failed to load font $fontName: $e");
      emit(GetFontErrorState());
    }
  }
  bool isFontLoaded(int pageNumber) {
    final fontName = "QCF_P${pageNumber.toString().padLeft(3, "0")}";
    return _loadedFonts.contains(fontName);
  }


  bool isLoading = true;

  var searchQuery = "";
  void changeSearchQuery(String value){
    searchQuery = value;
    emit(ChangeSearchQueryState());
  }
  List? filteredData;
  void changeFilteredData(value){
    filteredData = value;
    emit(ChangeFilteredDataState());
  }

  void searchForData() {
    ayatFiltered = [];

    // Normalize Arabic letters in the search query
    final normalizedQuery = _normalizeArabic(searchQuery);

    // Search ayat (verses)
    ayatFiltered = quran1.searchWords(normalizedQuery);

    // Filter suras
    filteredData = suraJsonData.where((sura) {
      final suraName = sura['englishName'].toLowerCase();
      final suraNameTranslated = _normalizeArabic(quran1.getSurahNameArabic(sura["number"]));

      return suraName.contains(normalizedQuery.toLowerCase()) ||
          suraNameTranslated.contains(normalizedQuery);
    }).toList();

    emit(SearchForDataState());
  }
  // Helper function to normalize Arabic text
  String _normalizeArabic(String input) {
    return input
    // Normalize Alif variations
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')

    // Normalize Waw and Ya variations
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ى', 'ي')

    // Normalize Taa Marbuta
        .replaceAll('ة', 'ه')
        .replaceAll('ۀ', 'ه')

    // Remove all diacritics (Tashkeel)
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '') // All Arabic diacritics
        .replaceAll(RegExp(r'[\u0670]'), '') // Dagger alif (ٰ)
        .replaceAll(RegExp(r'[\u06D6-\u06ED]'), '') // Quranic annotation marks

    // Remove Tatweel (kashida)
        .replaceAll('ـ', '')

    // Normalize Lam-Alif ligature
        .replaceAll('ﻻ', 'لا')
        .replaceAll('ﻷ', 'لا')
        .replaceAll('ﻹ', 'لا')
        .replaceAll('ﻵ', 'لا')

    // Handle special Quranic characters
        .replaceAll('ٱ', 'ا') // Alif Wasla

    // Normalize Allah (الله)
        .replaceAll('الرحم', 'الرحما')
        .replaceAll('اله', 'الاه')
        .replaceAll('ﷲ', 'الله')

    // Remove zero-width characters and other invisible Unicode
        .replaceAll(RegExp(r'[\u200B-\u200F\u202A-\u202E]'), '')

    // Trim whitespace
        .trim()

    // Normalize multiple spaces to single space
        .replaceAll(RegExp(r'\s+'), ' ');
  }
  List<Surah> surahList = [];
  var ayatFiltered;

  List pageNumbers = [];
  var suraJsonData;
  int? soraNumber ;

  loadJsonAsset() async {
    final String jsonString =
    await rootBundle.loadString('assets/json/surahs.json');
    var data = jsonDecode(jsonString);
    suraJsonData = data;
    emit(LoadJsonAssetState());
  }

  int homeCount = 20;
  int pageNumber = 0;
  void nextPage() {
    pageNumber++;
    emit(NextPageSuccessState());
  }

  void previousPage() {
    pageNumber--;
    emit(PreviousPageSuccessState());
  }
  // Timer? _searchDebounce;


  void loadMore() {
    if (homeCount + 20 < 114) {
      homeCount += 20;
    } else {
      homeCount = 114;
    }
    emit(IncreaseHomeCountSuccessState());
  }

  String convertToArabic(String number) {
    return number
        .replaceAll("AM", "صباحا")
        .replaceAll("PM", "مساءً")
        .replaceAll("0", "٠")
        .replaceAll("1", "١")
        .replaceAll("2", "٢")
        .replaceAll("3", "٣")
        .replaceAll("4", "٤")
        .replaceAll("5", "٥")
        .replaceAll("6", "٦")
        .replaceAll("7", "٧")
        .replaceAll("8", "٨")
        .replaceAll("9", "٩");
  }
  int savedSora = 0;
  int savedPage = 0;
  int savedVerse = 0;
  String placeOfRevelation = "";
  String savedVerseContent = "";

  void saveLastRead({
    required int page,
    required int verse,
    required int sora
}){
    CacheHelper.saveData(key: "page", value: page);
    CacheHelper.saveData(key: "verse", value: verse);
    CacheHelper.saveData(key: "sora", value: sora);
    getLastRead();
  }

  void getLastRead()async{
    savedSora = await CacheHelper.getData(key: "sora")??1;
    savedVerse = await CacheHelper.getData(key: "verse")??1;
    savedPage = await CacheHelper.getData(key: "page")??1;
    getPlaceOfRevelationAndVerseContent();
    emit(GetLastReadState());
  }

  void getPlaceOfRevelationAndVerseContent(){
   placeOfRevelation = quran.getPlaceOfRevelation(
        savedSora) ==
        "Makkah"
        ? "مكية"
        : "مدنية";
   savedVerseContent = quran.getVerse(savedSora, savedVerse);
   emit(GetPlaceOfRevelationState());
  }

  String verseTafseer = "";
  Future<void> getVerseTafseer({required int sora, required int verse})async{
    emit(GetVerseTafseerLoadingState());
    print("sora  $sora");
    print("verse  $verse");
    DioHelper.getData(url: "http://api.quran-tafseer.com/tafseer/8/${sora}/$verse").then((onValue){
      verseTafseer = onValue.data["text"];
      emit(GetVerseTafseerSuccessState());
    }).catchError((onError){
      print(onError);
      emit(GetVerseTafseerErrorState());
    });
  }

  final player = AudioServices().player;
  bool isPlaying = false;
  bool isPaused = false;

  Future<void> playSurahVerseByVerse({required int surahId}) async {
    try {
      emit(TextQuranLoadingState());
      final dio = Dio();
      final response = await dio.get(
        'https://api.quran.com/api/v4/verses/by_chapter/$surahId?language=ar',
      );

      if (response.statusCode != 200) {
        emit(TextQuranErrorState("Failed to fetch verses"));
        return;
      }

      final verses = response.data['verses'] as List;

      isPlaying = true;
      isPaused = false;
      savedSora = surahId;
      placeOfRevelation = quran.getPlaceOfRevelation(surahId) == "Makkah"
          ? "مكية"
          : "مدنية";

      emit(TextQuranPlayingState());

      int startIndex = 0;
      if ( savedVerse > 1) {
        startIndex = verses.indexWhere(
              (v) => v['verse_number'] == savedVerse,
        );
        if (startIndex == -1) startIndex = 0;
      }

      for  (var i = startIndex; i < verses.length; i++) {
        if (!isPlaying) break;
        if (isPaused) break;

        final verse = verses[i];
        print(verse);
        final verseKey = verse['verse_number'];
        final verseText = quran.getVerse(savedSora, verseKey);
        saveLastRead(page: verse['page_number'], verse: verseKey, sora: surahId);

        savedVerseContent = verseText;
        emit(TextQuranVerseChangedState(verseText));


        final audioUrl =
        quran.getAudioURLByVerse(surahId, verseKey, "ar.abdulbasitmurattal");

        await player.setAudioSource(
          AudioSource.uri(
            Uri.parse(audioUrl),
            tag: MediaItem(
              id: '$surahId:$verseText',
              album: 'Quran',
              title: 'سورة ${quran.getSurahNameArabic(surahId)} - آية $verseText',
              artist: 'عبد الباسط عبد الصمد',
            ),
          ),
        );
        await player.play();

        await player.processingStateStream.firstWhere(
              (state) =>
          state == ProcessingState.completed ||
              isPaused == true ||
              isPlaying == false,
        );

        if (isPaused) {
          await player.pause();
          break;
        }
      }
      if (isPlaying && !isPaused) {
        // ✅ Finished current surah — go to next automatically
        if (surahId < 114) {
          print('➡️ Finished Surah $surahId — starting next...');
          saveLastRead(page: 1, verse: 1, sora: surahId+1);
          await playSurahVerseByVerse(surahId: surahId + 1);
        } else {
          print('✅ Finished the full Quran!');
          isPlaying = false;
          emit(TextQuranStoppedState());
        }
      } else {
        isPlaying = false;
        emit(TextQuranStoppedState());
      }
    } catch (e) {
      print(e);
      emit(TextQuranErrorState(e.toString()));
    }
  }

  void togglePlayPause(int surahId) async {
    if (!isPlaying && !isPaused) {
      // Start playing
      isPlaying = true;
      playSurahVerseByVerse(surahId: surahId);
    } else if (isPlaying) {
      // Pause
      isPaused = true;
      isPlaying = false;
      player.pause();
      emit(TextQuranPausedState());
    } else if (isPaused) {
      // Resume
      isPaused = false;
      isPlaying = true;
      player.play();
      emit(TextQuranPlayingState());
    }
  }

  void stop() async {
    isPlaying = false;
    isPaused = true;
    await player.stop();
    emit(TextQuranStoppedState());
  }

  // 🔹 Filter variables
  String filterType = "all"; // "all", "surah", "juz"
  int? selectedSurah;
  int? selectedJuz;

  List<int> getFilteredSurahs() {
    List<int> surahs = List.generate(114, (index) => index + 1);

    if (filterType == "juz" && selectedJuz != null) {
      final int target = selectedJuz!;
      surahs = surahs.where((s) {
        final int verseCount = quran.getVerseCount(s);

        // quick include if the surah's first or last verse juz covers the target
        final int firstJuz = quran.getJuzNumber(s, 1);
        final int lastJuz  = quran.getJuzNumber(s, verseCount);
        if (target >= firstJuz && target <= lastJuz) return true;

        // fallback: scan verses (rare, for boundary cases)
        for (int ay = 1; ay <= verseCount; ay++) {
          if (quran.getJuzNumber(s, ay) == target) return true;
        }
        return false;
      }).toList();
    }

    if (filterType == "surah" && selectedSurah != null) {
      surahs = [selectedSurah!];
    }

    return surahs;
  }


  void setFilterType(String type) {
    filterType = type;
    if (type == "all") {
      selectedSurah = null;
      selectedJuz = null;
    }
    emit(ChangeFilterState());
  }

  void setSelectedSurah(int? surah) {
    selectedSurah = surah;
    emit(ChangeFilterState());
  }

  void setSelectedJuz(int? juz) {
    selectedJuz = juz;
    emit(ChangeFilterState());
  }

  void clearFilters() {
    filterType = "all";
    selectedSurah = null;
    selectedJuz = null;
    emit(ChangeFilterState());
  }

}
