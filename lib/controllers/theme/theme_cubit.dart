import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../components/cache_helper.dart';
import '../../constants/app_colors.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.dark);

  static ThemeCubit get(BuildContext context) => BlocProvider.of(context);

  bool isDark = true;
  bool isGold = false;

  Future<void> getThemeMode() async {
    final savedIsDark = await CacheHelper.getData(key: 'isDark');
    final savedIsGold = await CacheHelper.getData(key: 'isGold');

    isDark = savedIsDark ?? true;
    isGold = savedIsGold ?? false;
    AppColors.isGoldMode = isGold;

    _forceEmit();
  }

  Future<void> toggleTheme() async {
    isGold = false;
    AppColors.isGoldMode = false;

    isDark = !isDark;
    await CacheHelper.saveData(key: 'isDark', value: isDark);
    await CacheHelper.saveData(key: 'isGold', value: false);

    _forceEmit();
  }

  Future<void> enableGoldTheme() async {
    isGold = true;
    isDark = false;
    AppColors.isGoldMode = true;

    await CacheHelper.saveData(key: 'isGold', value: true);
    await CacheHelper.saveData(key: 'isDark', value: false);

    _forceEmit();
  }

  Future<void> setTheme(ThemeMode mode) async {
    isDark = mode == ThemeMode.dark;
    isGold = false;
    AppColors.isGoldMode = false;

    await CacheHelper.saveData(key: 'isDark', value: isDark);
    await CacheHelper.saveData(key: 'isGold', value: false);

    _forceEmit();
  }

  /// 🚀 Force rebuild even if ThemeMode does NOT change
  void _forceEmit() {
    final theme = _getThemeMode();

    emit(theme);            // desired theme
    emit(ThemeMode.system); // force rebuild
    emit(theme);            // switch back
  }

  ThemeMode _getThemeMode() {
    if (isGold) return ThemeMode.light;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Optional helper
  void refreshTheme() {
    emit(state);
  }
}
