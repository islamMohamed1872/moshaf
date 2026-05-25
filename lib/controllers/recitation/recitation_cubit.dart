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
  int dailyPagesTarget = 5;
  int totalPages = 604;
  int currentPage = 1;
  DateTime? startDate;
  DateTime? lastReadDate;
  int totalDaysToFinish = 0;
  int daysCompleted = 0;
  int daysLate = 0;
  bool hasActiveGoal = false;
  var suraJsonData;

  /// Pages read specifically today (resets each new calendar day)
  int todayPagesRead = 0;

  // ═══ COMPUTED GETTERS ═══
  double get progressPercentage => (currentPage / totalPages) * 100;

  /// Total pages remaining in the entire Quran journey
  int get totalPagesRemaining => totalPages - currentPage + 1;

  /// Pages still needed TODAY to hit the daily target (0 if completed/over-achieved)
  int get todayPagesRemaining =>
      (dailyPagesTarget - todayPagesRead).clamp(0, dailyPagesTarget);

  /// True once the user has read at least their daily target today
  bool get isTodayCompleted => todayPagesRead >= dailyPagesTarget;

  /// True when user has gone BEYOND their daily target today
  bool get isOverAchieved => todayPagesRead > dailyPagesTarget;

  int get extraPagesReadToday =>
      isOverAchieved ? todayPagesRead - dailyPagesTarget : 0;

  /// Returns the Rafeq image asset path based on current recitation status
  String get rafeqImageAsset {
    if (!hasActiveGoal) return 'assets/images/rafeq_reminder.png';
    if (isTodayCompleted) return 'assets/images/rafeq_excited.png';
    return 'assets/images/rafeq_sad.png';
  }

  /// Returns a context-aware message for the Rafeq widget
  String get rafeqMessage {
    if (!hasActiveGoal) {
      return 'لم تحدد وردك اليومي بعد!\nابدأ رحلتك مع القرآن الآن';
    }
    if (isOverAchieved) {
      return 'ممتاز! قرأت $todayPagesRead صفحة اليوم\nتجاوزت هدفك بـ $extraPagesReadToday صفحة!';
    }
    if (isTodayCompleted) {
      return 'أحسنت! أتممت وردك اليوم\nاستمر على هذا النهج';
    }
    return 'لم تكمل وردك اليوم بعد\nتبقى لك $todayPagesRemaining صفحة، هيا!';
  }

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

    dailyPagesTarget =
        await CacheHelper.getData(key: 'recitation_daily_pages') ?? 5;
    currentPage =
        await CacheHelper.getData(key: 'recitation_current_page') ?? 1;
    hasActiveGoal =
        await CacheHelper.getData(key: 'recitation_has_goal') ?? false;

    final startDateStr =
    await CacheHelper.getData(key: 'recitation_start_date');
    if (startDateStr != null) {
      startDate = DateTime.parse(startDateStr);
    }

    final lastReadStr =
    await CacheHelper.getData(key: 'recitation_last_read');
    if (lastReadStr != null) {
      lastReadDate = DateTime.parse(lastReadStr);
    }

    // ── Load today's pages only if lastReadDate is actually today ──
    final now = DateTime.now();
    final isLastReadToday = lastReadDate != null &&
        lastReadDate!.year == now.year &&
        lastReadDate!.month == now.month &&
        lastReadDate!.day == now.day;

    if (isLastReadToday) {
      todayPagesRead =
          await CacheHelper.getData(key: 'recitation_today_pages') ?? 0;
    } else {
      // New day — reset daily counter
      todayPagesRead = 0;
      await CacheHelper.saveData(key: 'recitation_today_pages', value: 0);
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
    todayPagesRead = 0;
    totalDaysToFinish = (totalPages / pagesPerDay).ceil();

    await CacheHelper.saveData(
        key: 'recitation_daily_pages', value: pagesPerDay);
    await CacheHelper.saveData(key: 'recitation_current_page', value: 1);
    await CacheHelper.saveData(
        key: 'recitation_start_date', value: startDate!.toIso8601String());
    await CacheHelper.saveData(key: 'recitation_has_goal', value: true);
    await CacheHelper.saveData(key: 'recitation_today_pages', value: 0);

    emit(RecitationUpdatedState());
  }

  // ═══ MARK PAGES READ (supports over-achievement) ═══
  Future<void> markPagesRead(int pagesToRead) async {
    if (!hasActiveGoal || pagesToRead <= 0) return;

    currentPage += pagesToRead;
    if (currentPage > totalPages) currentPage = totalPages;

    todayPagesRead += pagesToRead;
    lastReadDate = DateTime.now();

    // Only count daysCompleted on the day the target is first met
    if (todayPagesRead >= dailyPagesTarget &&
        todayPagesRead - pagesToRead < dailyPagesTarget) {
      daysCompleted++;
    }

    await CacheHelper.saveData(
        key: 'recitation_current_page', value: currentPage);
    await CacheHelper.saveData(
        key: 'recitation_last_read',
        value: lastReadDate!.toIso8601String());
    await CacheHelper.saveData(
        key: 'recitation_today_pages', value: todayPagesRead);

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
    todayPagesRead = 0;

    await CacheHelper.deleteData(key: 'recitation_current_page');
    await CacheHelper.deleteData(key: 'recitation_start_date');
    await CacheHelper.deleteData(key: 'recitation_last_read');
    await CacheHelper.deleteData(key: 'recitation_has_goal');
    await CacheHelper.deleteData(key: 'recitation_today_pages');

    emit(RecitationUpdatedState());
  }

  // ═══ COMPLETE RECITATION ═══
  Future<void> _completeRecitation() async {
    hasActiveGoal = false;
    await CacheHelper.saveData(key: 'recitation_has_goal', value: false);

    final completionDate = DateTime.now().toIso8601String();
    await CacheHelper.saveData(
        key: 'recitation_last_completion', value: completionDate);
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
    final endPage =
    (currentPage + dailyPagesTarget - 1).clamp(1, totalPages);

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
        if (dailyPagesTarget < 302) dailyPagesTarget++;
      } else {
        if (dailyPagesTarget > 1) dailyPagesTarget--;
      }
      emit(RecitationUpdateUIState());
    });
  }

  void stopAutoChange() {
    autoChangeTimer?.cancel();
    autoChangeTimer = null;
  }
}