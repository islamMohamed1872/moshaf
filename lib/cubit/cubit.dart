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



}
