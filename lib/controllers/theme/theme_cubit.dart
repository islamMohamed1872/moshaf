import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/components/cache_helper.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.dark);

  static ThemeCubit get(BuildContext context) => BlocProvider.of(context);

  bool isDark = true;

  /// 🔹 Load the saved theme mode from cache
  Future<void> getThemeMode() async {
    final bool? savedIsDark = await CacheHelper.getData(key: 'isDark');
    // Default to dark if null (first run)
    isDark = savedIsDark ?? true;
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  /// 🔹 Toggle between dark/light and persist the choice
  Future<void> toggleTheme() async {
    isDark = !isDark;
    await CacheHelper.saveData(key: 'isDark', value: isDark);
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  /// 🔹 Set a specific theme mode and persist it
  Future<void> setTheme(ThemeMode mode) async {
    isDark = mode == ThemeMode.dark;
    await CacheHelper.saveData(key: 'isDark', value: isDark);
    emit(mode);
  }
}
