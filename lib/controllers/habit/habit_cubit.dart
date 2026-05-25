
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/components/cache_helper.dart';
import 'package:moshaf/controllers/habit/habit_states.dart';
import 'package:moshaf/models/habit_model.dart';

class HabitCubit extends Cubit<HabitStates> {
  HabitCubit() : super(HabitInitialState());

  static HabitCubit get(context) => BlocProvider.of(context);

  static const String _cacheKey = 'user_habits';

  List<HabitModel> habits = [];

  Future<void> loadHabits() async {
    emit(HabitLoadingState());

    final cached = await CacheHelper.getData(key: _cacheKey);

    if (cached == null) {
      habits = _defaultHabits();
      await _saveHabits();
      emit(HabitLoadedState());
      return;
    }

    try {
      dynamic decoded;

      if (cached is String) {
        decoded = jsonDecode(cached);
      } else if (cached is List) {
        // old cache / stored list directly
        decoded = cached;
      } else {
        decoded = [];
      }

      if (decoded is List) {
        habits = decoded
            .whereType<Map>()
            .map((e) => HabitModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // print('📦 Habits loaded: ${habits.length}');
        emit(HabitLoadedState());
        return;
      }

      habits = [];
      emit(HabitLoadedState());
    } catch (e) {
      // print('❌ Failed to load habits cache: $e');
      habits = [];
      emit(HabitLoadedState());
    }
  }
  List<HabitModel> _defaultHabits() {
    final now = DateTime.now();

    return [
      // HabitModel(
      //   id: 'quran_daily',
      //   title: 'قراءة القرآن',
      //   icon: '📖',
      //   createdAt: now,
      //   completedDates: [],
      //   frequency: 'everyday',
      //   customDays: [],
      //   dailyTarget: 1,
      //   progressByDate: {},
      // ),
      // HabitModel(
      //   id: 'azkar_sabah',
      //   title: 'أذكار الصباح',
      //   icon: '🌤️',
      //   createdAt: now,
      //   completedDates: [],
      //   frequency: 'everyday',
      //   customDays: [],
      //   dailyTarget: 1,
      //   progressByDate: {},
      // ),
      // HabitModel(
      //   id: 'azkar_masaa',
      //   title: 'أذكار المساء',
      //   icon: '🌙',
      //   createdAt: now,
      //   completedDates: [],
      //   frequency: 'everyday',
      //   customDays: [],
      //   dailyTarget: 1,
      //   progressByDate: {},
      // ),
    ];
  }

  Future<void> addHabit({
    required String title,
    required String icon,
    required String frequency,
    required List<int> customDays,
    required int dailyTarget,
  }) async {
    final habit = HabitModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      icon: icon.trim().isEmpty ? '🌿' : icon.trim(),
      createdAt: DateTime.now(),
      completedDates: [],
      frequency: frequency,
      customDays: customDays,
      dailyTarget: dailyTarget <= 0 ? 1 : dailyTarget,
      progressByDate: {},
    );

    habits.add(habit);
    await _saveHabits();

    emit(HabitChangedState());
  }

  Future<void> incrementToday(String habitId) async {
    final index = habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final today = HabitModel.dateKey(DateTime.now());
    final habit = habits[index];

    final progress = Map<String, int>.from(habit.progressByDate);
    final current = progress[today] ?? 0;

    if (current < habit.dailyTarget) {
      progress[today] = current + 1;
    }

    final completedDates = List<String>.from(habit.completedDates);
    if ((progress[today] ?? 0) >= habit.dailyTarget &&
        !completedDates.contains(today)) {
      completedDates.add(today);
    }

    habits[index] = habit.copyWith(
      progressByDate: progress,
      completedDates: completedDates,
    );

    await _saveHabits();
    emit(HabitChangedState());
  }

  Future<void> decrementToday(String habitId) async {
    final index = habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final today = HabitModel.dateKey(DateTime.now());
    final habit = habits[index];

    final progress = Map<String, int>.from(habit.progressByDate);
    final current = progress[today] ?? 0;

    if (current > 0) {
      progress[today] = current - 1;
    }

    final completedDates = List<String>.from(habit.completedDates);
    if ((progress[today] ?? 0) < habit.dailyTarget) {
      completedDates.remove(today);
    }

    habits[index] = habit.copyWith(
      progressByDate: progress,
      completedDates: completedDates,
    );

    await _saveHabits();
    emit(HabitChangedState());
  }

  List<HabitModel> get todayHabits {
    return habits.where((h) => h.isScheduledToday()).toList();
  }

  int get completedTodayCount {
    return todayHabits.where((h) => h.isDoneToday()).length;
  }

  double get todayProgress {
    if (todayHabits.isEmpty) return 0;
    return completedTodayCount / todayHabits.length;
  }

  Future<void> deleteHabit(String habitId) async {
    habits.removeWhere((h) => h.id == habitId);
    await _saveHabits();
    emit(HabitChangedState());
  }

  Future<void> _saveHabits() async {
    final encoded = jsonEncode(
      habits.map((h) => h.toJson()).toList(),
    );

    await CacheHelper.saveData(
      key: _cacheKey,
      value: encoded,
    );

    // print('✅ Habits saved: $encoded');
  }

}