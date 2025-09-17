import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_states.dart';
import 'package:quran/quran.dart' as quran1;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../../components/cache_helper.dart';
import '../../../components/const.dart';
import '../models/sura.dart';

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
  var filteredData;
  void changeFilteredData(value){
    filteredData = value;
    emit(ChangeFilteredDataState());
  }

  void searchForData(){
    ayatFiltered = [];

    ayatFiltered = quran1.searchWords(searchQuery);
    filteredData =
        suraJsonData.where((sura) {
          final suraName =
          sura['englishName'].toLowerCase();
          // final suraNameTranslated =
          //     sura['name']
          //         .toString()
          //         .toLowerCase();
          final suraNameTranslated =
          quran1.getSurahNameArabic(sura["number"]);

          return suraName.contains(
            searchQuery.toLowerCase(),
          ) ||
              suraNameTranslated.contains(
                searchQuery.toLowerCase(),
              );
        }).toList();
    emit(SearchForDataState());
  }
  List<Surah> surahList = [];
  var ayatFiltered;

  List pageNumbers = [];
  var suraJsonData;

  loadJsonAsset() async {
    final String jsonString =
    await rootBundle.loadString('assets/json/surahs.json');
    var data = jsonDecode(jsonString);
    suraJsonData = data;
    emit(LoadJsonAssetState());
    addFilteredData();
  }

  addFilteredData() async {
    // await Future.delayed(const Duration(milliseconds: 600));
      filteredData = suraJsonData;
      isLoading = false;
      emit(AddFilteredDataState());
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
  Timer? _searchDebounce;


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

  void saveLastRead({
    required int page,
    required int verse,
    required int sora
}){
    CacheHelper.saveData(key: "page", value: page);
    CacheHelper.saveData(key: "verse", value: verse);
    CacheHelper.saveData(key: "sora", value: sora);
  }

  void getLastRead()async{
    savedSora = await CacheHelper.getData(key: "sora")??0;
    savedVerse = await CacheHelper.getData(key: "verse")??0;
    savedPage = await CacheHelper.getData(key: "page")??0;
  }



}