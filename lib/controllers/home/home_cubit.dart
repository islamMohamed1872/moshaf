import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bloc/bloc.dart';
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
import 'package:moshaf/views/azkar/prays_screen.dart';
import 'package:moshaf/views/haj_and_omrah/omrah_screen.dart';
import 'package:moshaf/views/mosque_location/mosque_location_screen.dart';
import 'package:moshaf/views/pray_teaching/pray_instructions_screen.dart';
import 'package:moshaf/views/prayer_times/prayer_times_screen.dart';
import 'package:moshaf/views/qiblah/qiblah_on_boarding_screen.dart';
import 'package:moshaf/views/quran/all_quran_screen.dart';
import 'package:moshaf/views/quran_radio/quran_radio_screen.dart';
import 'package:moshaf/views/ramadan/ramadan_screen.dart';
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

  Future<void> requestLocationPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // If disabled, we can prompt the user to enable it (optional)
        await Geolocator.openLocationSettings();
        throw Exception('Location services are disabled.');
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // Request permission if not granted
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied by user.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // User has permanently denied permission
        throw Exception('Location permission permanently denied.');
      }

      // If we reach here, permissions are granted → get current location
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Cache coordinates for later use
      CacheHelper.saveData(key: 'cached_latitude', value: pos.latitude);
      CacheHelper.saveData(key: 'cached_longitude', value: pos.longitude);

      print('✅ Location permissions granted and cached successfully: '
          '(${pos.latitude}, ${pos.longitude})');

      if (await PrayerTimesCubit().shouldFetchNewTimes()) {
        await PrayerTimesCubit().fetchPrayerTimes(); // Fetch new times if outdated
        await PrayerTimesCubit().scheduleDoaaNotifications(); // Fetch new times if outdated
      } else {
        await PrayerTimesCubit().loadCachedPrayerTimes(); // Load from cache if still valid
      }
    } catch (e) {
      print('⚠️ Error requesting location permissions: $e');

      // Try to fall back to cached location silently
      final cachedLat = await CacheHelper.getData(key: 'cached_latitude');
      final cachedLon = await CacheHelper.getData(key: 'cached_longitude');
      if (cachedLat != null && cachedLon != null) {
        print('📦 Using cached location: ($cachedLat, $cachedLon)');
      } else {
        print('❌ No cached location available.');
      }
    }
  }
}
