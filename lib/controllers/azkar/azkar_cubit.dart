import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/azkar.dart';
import 'package:moshaf/controllers/prayer_times/prayer_times_cubit.dart';
import 'package:vibration/vibration.dart';
import '../../components/audio_service.dart';
import '../../components/cache_helper.dart';
import '../../components/const.dart';
import '../../views/azkar/one_pray_screen.dart';
import '../../views/azkar/zekr_screen.dart';
import 'azkar_states.dart';

class AzkarCubit extends Cubit<AzkarStates> {
  AzkarCubit() : super(AzkarInitialState());
  static AzkarCubit get(context) => BlocProvider.of(context);


  // Data
  List<Map<String, dynamic>> azkar = [];
  List<dynamic> filteredAzkar = [];


  void decrementCount(Map<String, dynamic> item) {
    if (item['original_count'] == null) item["original_count"] = item['count'];
    int current = (item['count'] ?? 0) as int;
    if (current > 0) {
      item['count'] = current - 1;
      emit(AzkarLoadedState());
    }
    if(item['count']==0&&Platform.isAndroid){
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
  }

  void resetCount(Map<String, dynamic> item) {
    if (item['original_count'] != null) item['count'] = item['original_count'];
    emit(AzkarLoadedState());
  }


  final random = Random();
  String getRandomZekr(List<dynamic> list) {
    final randomItem = list[random.nextInt(list.length)];
    return randomItem['zekr'] ?? ''; // Return the zekr text safely
  }
  String randomZekr = "";
  String zekrCategory = "";
  void getZekrBasedOnTime(context)async {
    DateTime now = DateTime.now();
    // Example lists
    final azkarAlAdhan = AzkarConstants.azkarAlAdhan;
    final azkarBaadAlsalah = AzkarConstants.azkarBaadAlsalah;
    final azkarSabah = AzkarConstants.azkarSabah;
    final azkarMasaa = AzkarConstants.azkarMasaa;
    final azkarMotafareqa = AzkarConstants.azkarMotafareqa;
    final prayerTimes = PrayerTimesCubit.get(context).prayerTimes;
    if(prayerTimes.isEmpty){
     await PrayerTimesCubit.get(context).fetchPrayerTimesNoInternet();
    }

    // 1. Check if just after any prayer time
    for (var entry in prayerTimes.entries) {
      final prayerTime = entry.value;
      final difference = now.difference(prayerTime).inMinutes;

      if (difference >= 0 && difference <= 2) {
        print(getRandomZekr(azkarAlAdhan['azkar']));
        randomZekr = getRandomZekr(azkarAlAdhan['azkar']);
        zekrCategory = azkarAlAdhan['category'];
        emit(GetZekrBasedOnTimeState());
        return;
      } else if (difference > 2 && difference <= 5) {
        randomZekr = getRandomZekr(azkarBaadAlsalah['azkar']);
        zekrCategory = azkarBaadAlsalah['category'];
        emit(GetZekrBasedOnTimeState());
        return;
      }
    }

    // 2. Morning (after Fajr until Shorouq)
    if (now.isAfter(prayerTimes["الفجر"]!) && now.isBefore(prayerTimes["الشروق"]!)) {
      randomZekr = getRandomZekr(azkarSabah['azkar']);
      zekrCategory = azkarSabah['category'];
      emit(GetZekrBasedOnTimeState());
      return;
    }

    // 3. Evening (after Maghrib until Isha)
    if (now.isAfter(prayerTimes["المغرب"]!) && now.isBefore(prayerTimes["العشاء"]!)) {
      randomZekr = getRandomZekr(azkarMasaa['azkar']);
      zekrCategory = azkarMasaa['category'];
      emit(GetZekrBasedOnTimeState());
      return;
    }

    //  4. Otherwise
    randomZekr = getRandomZekr(azkarMotafareqa['azkar']);
    zekrCategory = azkarMotafareqa['category'];
    emit(GetZekrBasedOnTimeState());
    return;
  }
  void navigateToRelatedAzkarScreen(BuildContext context, String category) async {
    final categories = {
      "أذكار الصباح": AzkarConstants.azkarSabah,
      "أذكار المساء": AzkarConstants.azkarMasaa,
      "أذكار بعد الصلاة": AzkarConstants.azkarBaadAlsalah,
      "أذكار الأذان": AzkarConstants.azkarAlAdhan,
      "أذكار متفرقة": AzkarConstants.azkarMotafareqa,
      "أذكار الاستيقاظ": AzkarConstants.azkarAlIstiqaz,
      "أذكار النوم": AzkarConstants.azkarAlNawm,
      "أذكار المسجد": AzkarConstants.azkarAlMasjid,
      "أذكار الطعام": AzkarConstants.azkarAlTaam,
      "أذكار الوضوء": AzkarConstants.azkarAlWudu,
      "أذكار الحج والعمرة": AzkarConstants.azkarAlHajjWalUmrah,
      "أذكار المنزل": AzkarConstants.azkarAlManzil,
    };

    final original = categories[category];
    if (original == null) return;

    final Map<String, dynamic> selected = {
      ...original,
      'azkar': List<Map<String, dynamic>>.from(
        (original['azkar'] as List).map((e) => Map<String, dynamic>.from(e)),
      ),
    };


    navigateTo(
      context,
      ZekrScreen(
        title: category,
        items: selected,
      ),
    );
  }

  String randomDoaa = "";
  String doaaCategory = "";
  void getRandomDuaa() {
    List doaa = [
      AzkarConstants.jawameDoaa,
      AzkarConstants.adeyahNabaweyah,
      AzkarConstants.adeyaQuranya,
    ];
    final randomDoaaListIndex = random.nextInt(doaa.length);

    if (doaa[randomDoaaListIndex]["azkar"].isEmpty) return;
    final randomIndex = random.nextInt(doaa[randomDoaaListIndex]["azkar"].length);
    randomDoaa= doaa[randomDoaaListIndex]["azkar"][randomIndex]["zekr"];
    doaaCategory= doaa[randomDoaaListIndex]["category"];
    emit(GetRandomDuaa());
  }

  void navigateToRelatedDoaaScreen( context, String category,bool isDark) {
    final categories = {
      "جوامع الدعاء": AzkarConstants.jawameDoaa,
      "أدعية نبوية": AzkarConstants.adeyahNabaweyah,
      "أدعية قرآنية": AzkarConstants.adeyaQuranya,
    };

    final selected = categories[category];
    if (selected != null) {
      navigateTo(context, OnePrayScreen(title: category, items: selected,isDark: isDark,));
    }
  }

  bool isSwipeView = false;

  void toggleViewMode() {
    isSwipeView = !isSwipeView;
    emit(ChangeViewModeState());
  }

  PageController pageController = PageController();

  int currentSwipeIndex = 0;

  void changeSwipeIndex(int idx) {
    currentSwipeIndex = idx;
    emit(ChangeSwipeIndexState()); // create state class
  }


  final Map<String, List<int>> _azkarOrderCache = {}; // categoryId -> reordered indices

  /// Save the current order of azkar items for a category
  Future<void> saveZekrOrder(String categoryId, List<Map<String, dynamic>> orderedItems) async {
    try {
      // Create a mapping of original positions
      final orderMap = <String, int>{};
      for (int i = 0; i < orderedItems.length; i++) {
        final item = orderedItems[i];
        final itemId = item['id'] as String? ?? '${categoryId}_${item.hashCode}';
        orderMap[itemId] = i;
      }

      // Save to cache
      await CacheHelper.saveMap(
        key: 'azkar_order_$categoryId',
        myMap: orderMap,
      );

      _azkarOrderCache[categoryId] = orderedItems
          .asMap()
          .entries
          .map((e) => e.key)
          .toList();

      print('Saved order for category: $categoryId');
    } catch (e) {
      print('Error saving azkar order: $e');
    }
  }

  /// Load saved order for a category and reorder items
  Future<List<Map<String, dynamic>>> loadZekrOrder(
      String categoryId,
      List<Map<String, dynamic>> originalItems,
      ) async {
    try {
      final cached = await CacheHelper.getMap(key: 'azkar_order_$categoryId');

      if (cached == null || cached.isEmpty) {
        print('No saved order found for: $categoryId');
        return originalItems;
      }

      // Create a map of itemId -> original item
      final itemMap = <String, Map<String, dynamic>>{};
      for (final item in originalItems) {
        final itemId = item['id'] as String? ?? '${categoryId}_${item.hashCode}';
        itemMap[itemId] = item;
      }

      // Reorder based on saved order
      final reorderedItems = <Map<String, dynamic>>[];
      cached.forEach((itemId, _) {
        if (itemMap.containsKey(itemId)) {
          reorderedItems.add(itemMap[itemId]!);
        }
      });

      // Add any new items that weren't in saved order
      for (final item in originalItems) {
        final itemId = item['id'] as String? ?? '${categoryId}_${item.hashCode}';
        if (!reorderedItems.any((e) => (e['id'] ?? e.hashCode) == itemId)) {
          reorderedItems.add(item);
        }
      }

      print('Loaded saved order for category: $categoryId');
      return reorderedItems;
    } catch (e) {
      print(' Error loading azkar order: $e');
      return originalItems;
    }
  }

  /// Clear saved order for a category (when user resets)
  Future<void> clearZekrOrder(String categoryId) async {
    try {
      await CacheHelper.deleteData(key: 'azkar_order_$categoryId');
      _azkarOrderCache.remove(categoryId);
      print(' Cleared order for category: $categoryId');
    } catch (e) {
      print(' Error clearing azkar order: $e');
    }
  }

  /// Clear all saved orders
  Future<void> clearAllZekrOrders() async {
    try {
      for (final categoryId in _azkarOrderCache.keys.toList()) {
        await clearZekrOrder(categoryId);
      }
      print(' Cleared all saved orders');
    } catch (e) {
      print('Error clearing all orders: $e');
    }
  }


}
