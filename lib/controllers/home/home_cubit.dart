import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moshaf/components/cache_helper.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/controllers/home/home_states.dart';
import 'package:moshaf/controllers/azkar/azkar_cubit.dart';
import 'package:moshaf/views/admin/add_challenge.dart';
import 'package:moshaf/views/azkar/prays_screen.dart';
import 'package:moshaf/views/daily_challenge/daily_challenge_screen.dart';
import 'package:moshaf/views/haj_and_omrah/omrah_screen.dart';
import 'package:moshaf/views/leaderboard/leaderboard_screen.dart';
import 'package:moshaf/views/mosque_location/mosque_location_screen.dart';
import 'package:moshaf/views/podcasts/podcasts_screen.dart';
import 'package:moshaf/views/pray_teaching/pray_instructions_screen.dart';
import 'package:moshaf/views/prayer_times/prayer_times_screen.dart';
import 'package:moshaf/views/qiblah/qiblah_on_boarding_screen.dart';
import 'package:moshaf/views/quran/all_quran_screen.dart';
import 'package:moshaf/views/quran_radio/quran_radio_screen.dart';
import 'package:moshaf/views/ramadan/ramadan_screen.dart';
import 'package:moshaf/views/recitation/recitation_screen.dart';
import 'package:moshaf/views/search/search_screen.dart';
import 'package:moshaf/views/tasbeeh/tasbeeh_screen.dart';
import 'package:moshaf/views/wodoo_teaching/wodoo_instructions_screen.dart';
import 'package:moshaf/views/zakat_al_mal/zakah_calculator.dart';
import 'package:quran/quran.dart' as quran;
import 'package:workmanager/workmanager.dart';

import '../../constants/azkar.dart';
import '../prayer_times/prayer_times_cubit.dart';
import '../../views/azkar/azkar_screen.dart';
import '../../views/azkar/one_pray_screen.dart';

class HomeCubit extends Cubit<HomeStates>{
  HomeCubit() : super(HomeInitialState());
  static HomeCubit get(context) => BlocProvider.of(context);
  bool? isFirstTime;
  void setFirstTime(){
    isFirstTime = false;
    CacheHelper.saveData(key: "isFirstTime", value: isFirstTime);
    emit(IsFirstTimeState());
  }
  void getFirstTime()async{
    isFirstTime = await CacheHelper.getData(key: "isFirstTime")??true;
    emit(IsFirstTimeState());
  }

  // Mock data for grid items
  final List<Map<String, String>> gridItems = [
    {"image": "assets/images/prayer_times.png", "title": "توقيت الصلاة"},
    {"image": "assets/images/quran.png", "title": "القرآن الكريم"},
    {"image": "assets/images/hadith.png", "title": "احاديث نبوية"},
    {"image": "assets/images/prays.png", "title": "ادعية واذكار"},
    {"image": "assets/images/wodoo.png", "title": "تعليم الوضوء"},
    {"image": "assets/images/pray_teaching.png", "title": "تعليم الصلاة"},
    {"image": "assets/images/qiblah.png", "title": "تحديد القبلة"},
    {"image": "assets/images/masjed.png", "title": "مساجد"},
    {"image": "assets/images/ramadan.png", "title": "شهر رمضان"},
    {"image": "assets/images/haj.png", "title": "مناسك الحج والعمرة"},
    {"image": "assets/images/tasbeeh.png", "title": "السبحة"},
    {"image": "assets/images/zakah.png", "title": "حساب زكاة المال"},
    {"image": "assets/images/radio.png", "title": "اذاعة القرآن الكريم"},
    {"image": "assets/images/search.png", "title": "بحث"},
    {"image": "assets/images/podcast.png", "title": "مقاطع الفيديو"},
    {"image": "assets/images/holy.png", "title": "الوِرد"},
    // {"image": "assets/images/bulb.png", "title": "لغز"},
    // {"image": "assets/images/leaderboard.png", "title": "لوحة المتصدرين"},
    // if(FirebaseAuth.instance.currentUser!=null&&FirebaseAuth.instance.currentUser!.email=="islam.mohamed1872@gmail.com")
    // {"image": "assets/images/admin.png", "title": "admin"},
  ];

  void navigateToFeature(BuildContext context, int index,bool isDark) {
    switch (index) {
      case 0:
        navigateTo(context, PrayerTimesScreen());
        break;
      case 1:
        navigateTo(context, AllQuranScreen());
        break;
      case 2:
        navigateTo(context, OnePrayScreen(title: "ادعية نبوية", items: AzkarConstants.adeyahNabaweyah,isDark: isDark));
        break;
      case 3:
        AzkarCubit.get(context).getZekrBasedOnTime(context);
        navigateTo(context, AzkarScreen());
        break;
      case 4:
        navigateTo(context, WodooInstructionsScreen());
        break;
      case 5:
        navigateTo(context, PrayInstructionsScreen());
        break;
      case 6:
        navigateTo(context, QiblahOnBoardingScreen());
        break;
      case 7:
        navigateTo(context, MosqueLocationScreen());
        break;
      case 8:
        navigateTo(context, RamadanScreen());
        break;
      case 9:
        navigateTo(context, OmrahScreen(isDark: isDark,));
        break;
      case 10:
        navigateTo(context, TasbeehScreen());
        break;
      case 11:
        navigateTo(context, ZakahCalculator());
        break;
      case 12:
        navigateTo(context, QuranRadioScreen());
        break;
      case 13:
        navigateTo(context, SearchScreen());
        break;
      case 14:
        navigateTo(context, PodcastsScreen());
        break;
      case 15:
        navigateTo(context, RecitationScreen());
        break;
      case 16:
        navigateTo(context, DailyChallengeScreen());
        break;
      case 17:
        navigateTo(context, LeaderboardScreen());
        break;
      case 18:
        navigateTo(context, AdminAddChallengeScreen());
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم إضافة هذه الميزة بعد')),
        );
    }
  }

  String athkar = "";
  Future<String> getRandomAthkar() async {
    final data = await rootBundle.loadString('assets/json/athkar.json');
    final List<dynamic> list = json.decode(data);
    final random = Random();
    athkar =  list[random.nextInt(list.length)];
    emit(GetRandomAthkarState());
    await Future.delayed(Duration(minutes: 12));
    emit(GetNewRandomAthkarState());
    return athkar;
  }

  Future<void> requestOverlay() async {
    if (!Platform.isAndroid) return;
    bool status = await FlutterOverlayWindow.isPermissionGranted();

    if (!status) {
      // Request the permission
      await FlutterOverlayWindow.requestPermission();
      return; // Stop here and ask user to retry after granting
    }
  }

  Future<void> requestLocationOnce() async {
    try {
      // Check if location already initialized
      final bool isInitialized =
          await CacheHelper.getData(key: "location_initialized") ?? false;

      if (isInitialized) {
        // ✅ Use cached location silently
        final cachedLat = await CacheHelper.getData(key: 'cached_latitude');
        final cachedLon = await CacheHelper.getData(key: 'cached_longitude');

        if (cachedLat != null && cachedLon != null) {
          print('📦 Using cached location: ($cachedLat, $cachedLon)');
          return;
        }

        // Edge case: flag true but cache missing → reset
        await CacheHelper.saveData(key: "location_initialized", value: false);
      }

      // 🚨 FIRST TIME ONLY — request permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw Exception('Location services disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // 📍 Get location ONCE
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 💾 Cache values
      await CacheHelper.saveData(key: 'cached_latitude', value: pos.latitude);
      await CacheHelper.saveData(key: 'cached_longitude', value: pos.longitude);
      await CacheHelper.saveData(key: "location_initialized", value: true);

      print('✅ Location cached: (${pos.latitude}, ${pos.longitude})');

      // Optional: trigger prayer times update ONCE
      if (await PrayerTimesCubit().shouldFetchNewTimes()) {
        await PrayerTimesCubit().fetchPrayerTimesNoInternet();
      } else {
        await PrayerTimesCubit().loadCachedPrayerTimes();
      }
    } catch (e) {
      print('⚠️ Location init failed: $e');

      // Fallback to cached location if exists
      final cachedLat = await CacheHelper.getData(key: 'cached_latitude');
      final cachedLon = await CacheHelper.getData(key: 'cached_longitude');

      if (cachedLat != null && cachedLon != null) {
        print('📦 Fallback cached location: ($cachedLat, $cachedLon)');
      } else {
        print('❌ No cached location available');
      }
    }
  }
}
