import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:moshaf/cubit/states.dart';
import 'package:moshaf/modules/audio_quran/shiekh_screen.dart';
import 'package:moshaf/modules/prayer_times/cubit/prayer_times_cubit.dart';
import 'package:moshaf/modules/text_quran/views/all_quran_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/cache_helper.dart';
import '../modules/azkar/azkar_screen.dart';
import '../modules/prayer_times/praye_time_screen.dart';
import '../modules/text_quran/saved_screen.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitialState());
  static AppCubit get(context) => BlocProvider.of(context);

  int currentIndex = 0;

  List<Widget> bottomScreens = [
    QuranPage(),
    ShiekhScreen(),
    AzkarScreen(),
    PrayTimeScreen(),
    SavedScreen(),
  ];
  void changeBottom(int index) {
    currentIndex = index;
    emit(AppChangeBottomNavState());
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
