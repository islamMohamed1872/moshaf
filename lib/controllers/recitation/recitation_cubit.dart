import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/controllers/recitation/recitation_state.dart';
import 'package:quran/quran.dart' as quran;

import '../../components/cache_helper.dart';

class RecitationCubit extends Cubit<RecitationStates> {
  RecitationCubit() : super(RecitationInitialState());

  static RecitationCubit get(context) => BlocProvider.of(context);

  // ═══ DATA FIELDS ═══
  int dailyPagesTarget = 5; // Default: 5 pages per day
  int totalPages = 604; // Total Quran pages
  int currentPage = 1; // Current page user is on
  DateTime? startDate; // When user started
  DateTime? lastReadDate; // Last time user read
  int totalDaysToFinish = 0; // Total days needed
  int daysCompleted = 0; // Days user has read
  int daysLate = 0; // Days user missed
  bool hasActiveGoal = false;
  var suraJsonData;

  // Progress tracking
  double get progressPercentage => (currentPage / totalPages) * 100;
  int get pagesRemaining => totalPages - currentPage + 1;
  int get expectedPage {
    if (startDate == null) return 1;
    final daysPassed = DateTime.now().difference(startDate!).inDays;
    return (1 + (daysPassed * dailyPagesTarget)).clamp(1, totalPages);
  }

  loadJsonAsset() async {
    final String jsonString =
    await rootBundle.loadString('assets/json/surahs.json');
    var data = jsonDecode(jsonString);
    suraJsonData = data;
    emit(LoadJsonAssetState());
  }

  // ═══ INITIALIZATION ═══
  Future<void> initializeRecitation() async {
    emit(RecitationLoadingState());


    // Load saved data
    dailyPagesTarget = await CacheHelper.getData(key: 'recitation_daily_pages') ?? 5;
    currentPage = await CacheHelper.getData(key: 'recitation_current_page') ?? 1;
    hasActiveGoal = await CacheHelper.getData(key: 'recitation_has_goal') ?? false;

    final startDateStr = await CacheHelper.getData(key: 'recitation_start_date');
    if (startDateStr != null) {
      startDate = DateTime.parse(startDateStr);
    }

    final lastReadStr = await CacheHelper.getData(key: 'recitation_last_read');
    if (lastReadStr != null) {
      lastReadDate = DateTime.parse(lastReadStr);
    }

    _calculateProgress();
    emit(RecitationLoadedState());
  }

  // ═══ START NEW GOAL ═══
  Future<void> startNewGoal(int pagesPerDay) async {
    dailyPagesTarget = pagesPerDay;
    currentPage = 1;
    startDate = DateTime.now();
    lastReadDate = null;
    hasActiveGoal = true;
    daysCompleted = 0;
    totalDaysToFinish = (totalPages / pagesPerDay).ceil();

    // Save to cache
    await CacheHelper.saveData(key: 'recitation_daily_pages', value: pagesPerDay);
    await CacheHelper.saveData(key: 'recitation_current_page', value: 1);
    await CacheHelper.saveData(key: 'recitation_start_date', value: startDate!.toIso8601String());
    await CacheHelper.saveData(key: 'recitation_has_goal', value: true);

    emit(RecitationUpdatedState());
  }

  // ═══ MARK PAGE AS READ ═══
  Future<void> markPagesRead(int pagesToRead) async {
    if (!hasActiveGoal) return;

    currentPage += pagesToRead;
    if (currentPage > totalPages) currentPage = totalPages;

    lastReadDate = DateTime.now();
    daysCompleted++;

    // Save progress
    await CacheHelper.saveData(key: 'recitation_current_page', value: currentPage);
    await CacheHelper.saveData(key: 'recitation_last_read', value: lastReadDate!.toIso8601String());

    // Check if finished
    if (currentPage >= totalPages) {
      await _completeRecitation();
    }

    _calculateProgress();
    emit(RecitationUpdatedState());
  }

  // ═══ CALCULATE DAYS LATE ═══
  void _calculateProgress() {
    if (startDate == null || !hasActiveGoal) {
      daysLate = 0;
      return;
    }

    final daysSinceStart = DateTime.now().difference(startDate!).inDays;
    final expectedCurrentPage = 1 + (daysSinceStart * dailyPagesTarget);
    final pagesBehind = expectedCurrentPage - currentPage;

    daysLate = (pagesBehind / dailyPagesTarget).floor().clamp(0, 9999);
  }

  // ═══ RESET GOAL ═══
  Future<void> resetGoal() async {
    currentPage = 1;
    startDate = null;
    lastReadDate = null;
    hasActiveGoal = false;
    daysCompleted = 0;
    daysLate = 0;

    await CacheHelper.deleteData(key: 'recitation_current_page');
    await CacheHelper.deleteData(key: 'recitation_start_date');
    await CacheHelper.deleteData(key: 'recitation_last_read');
    await CacheHelper.deleteData(key: 'recitation_has_goal');

    emit(RecitationUpdatedState());
  }

  // ═══ COMPLETE RECITATION ═══
  Future<void> _completeRecitation() async {
    hasActiveGoal = false;
    await CacheHelper.saveData(key: 'recitation_has_goal', value: false);

    // Save to history
    final completionDate = DateTime.now().toIso8601String();
    await CacheHelper.saveData(key: 'recitation_last_completion', value: completionDate);
  }

  // ═══ GET START/END VERSES FOR PAGE ═══
  Map<String, dynamic> getPageInfo(int page) {
    if (page < 1 || page > 604) return {};

    final pageData = quran.getPageData(page);
    if (pageData.isEmpty) return {};

    final firstSurah = pageData.first['surah'];
    final firstVerse = pageData.first['start'];
    final lastSurah = pageData.last['surah'];
    final lastVerse = pageData.last['end'];
    return {
      'startSurah': firstSurah,
      'startVerse': firstVerse,
      'endSurah': lastSurah,
      'endVerse': lastVerse,
      'startSurahName': quran.getSurahNameArabic(firstSurah),
      'endSurahName': quran.getSurahNameArabic(lastSurah),
      'startSurahNumber': firstSurah,
      'endSurahNumber': lastSurah,
    };
  }

  // ═══ GET DAILY READING RANGE ═══
  Map<String, dynamic> getDailyReadingRange() {
    final startPage = currentPage;
    final endPage = (currentPage + dailyPagesTarget - 1).clamp(1, totalPages);

    final startInfo = getPageInfo(startPage);
    final endInfo = getPageInfo(endPage);

    return {
      'startPage': startPage,
      'endPage': endPage,
      'startSurahNumber': startInfo['startSurahNumber'],
      'endSurahNumber': endInfo['endSurahNumber'],
      'pagesCount': endPage - startPage + 1,
      'startInfo': startInfo,
      'endInfo': endInfo,
    };
  }

  Timer? autoChangeTimer;

  void startAutoChange({required bool isIncrement}) {
    autoChangeTimer?.cancel();

    autoChangeTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (isIncrement) {
        if (dailyPagesTarget < 302) {
          dailyPagesTarget++;
        }
      } else {
        if (dailyPagesTarget > 1) {
          dailyPagesTarget--;
        }
      }

      emit(RecitationUpdateUIState());
    });
  }

  void stopAutoChange() {
    autoChangeTimer?.cancel();
    autoChangeTimer = null;
  }
}