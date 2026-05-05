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
import 'package:moshaf/controllers/ramadan/ramadan_states.dart';
import 'package:moshaf/views/admin/add_challenge.dart';
import 'package:moshaf/views/azkar/prays_screen.dart';
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
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:workmanager/workmanager.dart';

import '../../constants/azkar.dart';
import '../../views/ramadan/daily_challenge_screen.dart';
import '../prayer_times/prayer_times_cubit.dart';
import '../../views/azkar/azkar_screen.dart';
import '../../views/azkar/one_pray_screen.dart';

import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/controllers/home/home_states.dart';

class RamadanCubit extends Cubit<RamadanStates> {
  RamadanCubit() : super(RamadanInitialState());

  static RamadanCubit get(context) => BlocProvider.of(context);



  // Mock data for grid items
  final List<Map<String, String>> gridItems = [
    {"image": "assets/images/bulb.png", "title": "التحدي اليومي"},
    {"image": "assets/images/leaderboard.png", "title": "لوحة المتصدرين"},
    // {"image": "assets/images/podcast.png", "title": "admin"},
  ];

  void navigateToFeature(BuildContext context, int index, bool isDark) {
    if(FirebaseAuth.instance.currentUser==null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برجاء تسجيل الدخول اولاً')),
      );
      return ;
    }
    switch (index) {
      case 0:
        navigateTo(context, DailyChallengeScreen());
        break;
      case 1:
        navigateTo(context, LeaderboardScreen());
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم إضافة هذه الميزة بعد')),
        );
    }
  }


}
