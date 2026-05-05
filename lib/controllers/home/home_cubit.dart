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
import 'package:moshaf/views/hadith/hadith_screen.dart';
import 'package:moshaf/views/azkar/prays_screen.dart';
import 'package:moshaf/views/haj_and_omrah/omrah_screen.dart';
import 'package:moshaf/views/leaderboard/leaderboard_screen.dart';
import 'package:moshaf/views/mosque_location/mosque_location_screen.dart';
import 'package:moshaf/views/podcasts/podcasts_screen.dart';
import 'package:moshaf/views/pray_teaching/pray_instructions_screen.dart';
import 'package:moshaf/views/prayer_times/prayer_times_screen.dart';
import 'package:moshaf/views/qiblah/qiblah_on_boarding_screen.dart';
import 'package:moshaf/views/quran/all_quran_screen.dart';
import 'package:moshaf/views/quran/quran_main_screen.dart';
import 'package:moshaf/views/quran_radio/quran_radio_screen.dart';
import 'package:moshaf/views/ramadan/ramadan_home.dart';
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
import '../prayer_times/prayer_times_cubit.dart';
import '../../views/azkar/azkar_screen.dart';
import '../../views/azkar/one_pray_screen.dart';

import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/controllers/home/home_states.dart';

class HomeCubit extends Cubit<HomeStates> {
  HomeCubit() : super(HomeInitialState());

  static HomeCubit get(context) => BlocProvider.of(context);


  bool? isFirstTime;
  final ScrollController homeScrollController = ScrollController();

  int tutorialIndex = 0;
  bool tutorialRunning = false;

  TutorialCoachMark? activeCoach;

  bool _tutorialLock = false;

  /// ✅ prevents showing the same step twice (THIS FIXES YOUR BUG)
  int? _showingStep;

  Future<void> getFirstTime() async {
    isFirstTime = await CacheHelper.getData(key: "isFirstTime2") ?? true;
    emit(IsFirstTimeState());
  }

  void setFirstTime() {
    isFirstTime = false;
    CacheHelper.saveData(key: "isFirstTime2", value: false);
    emit(IsFirstTimeState());
  }

  void startTutorial() {
    if (tutorialRunning || _tutorialLock) return;

    _tutorialLock = true;
    tutorialRunning = true;
    tutorialIndex = 0;
    _showingStep = null;

    emit(HomeTutorialStarted());
    emit(HomeTutorialStepRequested(tutorialIndex));
  }

  /// ✅ this is called after pressing finish
  void requestNextStep() {
    if (!tutorialRunning) return;

    tutorialIndex++;
    emit(HomeTutorialStepRequested(tutorialIndex));
  }

  /// ✅ called by UI when it starts showing a step
  bool markStepAsShowing(int step) {
    if (_showingStep == step) return false;
    _showingStep = step;
    return true;
  }

  void finishTutorial() {
    tutorialRunning = false;
    tutorialIndex = 0;

    closeCoach();
    setFirstTime();

    _tutorialLock = false;
    _showingStep = null;

    emit(HomeTutorialFinished());
  }

  void closeCoach() {
    try {
      activeCoach?.finish();
    } catch (_) {}
    activeCoach = null;
  }

  List coachContent = [
    {
      "title" :"مواعيد الصلاة 🕌",
      "content" : "هنا ستجد كل أوقات الصلاة بدقة، ومعرفة الصلاة القادمة والوقت المتبقي لها، بالإضافة إلى التاريخ الهجري والميلادي."
    },
    {
      "title" :"توقيت الصلاة ⏳",
      "content" : "اعرف مواقيت الصلوات كاملة، وشاهد الوقت المتبقي حتى الصلاة القادمة في أي وقت بسهولة."
    },
    {
      "title" :"القرآن الكريم 📖",
      "content" : "اقرأ القرآن كاملًا مع إمكانية التحميل للاستخدام بدون إنترنت، واستعرض التفسير، واحفظ آخر موضع قراءة. كما يمكنك الاستماع بصوت أشهر القرّاء وإنشاء قوائم تشغيل (Playlists)."
    },
    {
      "title" :"أحاديث نبوية ﷺ",
      "content" : "مجموعة مختارة من أحاديث النبي محمد ﷺ لتتعلم منها وتعيش مع نور السنة في كل يوم."
    },
    {
      "title" :"أدعية وأذكار 🤲",
      "content" : "موسوعة ضخمة من الأذكار والأدعية لكل موقف في حياتك، مع فوائد عظيمة تساعدك على الثبات والطمأنينة."
    },
    {
      "title" :"تعليم الوضوء 💧",
      "content" : "علّم أطفالك الوضوء خطوة بخطوة مع شرح بسيط وصور واضحة تساعدهم على التعلم بسهولة."
    },
    {
      "title" :"تعليم الصلاة 🧎‍♂️",
      "content" : "شرح مبسط لتعليم الأطفال كيفية أداء الصلاة بشكل صحيح خطوة بخطوة، بطريقة سهلة وممتعة."
    },
    {
      "title" :"تحديد القبلة 🧭",
      "content" : "اعرف اتجاه القبلة أينما كنت بدقة عالية… لتصلي في أي مكان بثقة واطمئنان."
    },
    {
      "title" :"مساجد قريبة 🕌📍",
      "content" : "اعرف أماكن المساجد من حولك، وحدد أقرب مسجد بسهولة أينما كنت."
    },
    {
      "title" :"شهر رمضان 🌙",
      "content" : "مميزات وتجهيزات رمضان قادمة قريبًا بإذن الله… تابع معنا لتجربة رمضانية مختلفة ومميزة ❤️"
    },
    {
      "title" :"مناسك الحج والعمرة 🕋",
      "content" : "تعرف على خطوات الحج والعمرة بشكل مرتب وواضح لمساعدتك على أداء المناسك بطريقة صحيحة."
    },
    {
      "title" :"السبحة ✨",
      "content" : "سبحة إلكترونية رائعة مع أنيميشن جميل، ويمكنك إضافة الذكر الذي تريد عدّه بسهولة والاستمرار يوميًا."
    },
    {
      "title" :"حساب زكاة المال 💰",
      "content" : "احسب زكاتك بسهولة وبدقة، مع أدوات تساعدك في معرفة مقدار الزكاة المستحق بطريقة بسيطة."
    },
    {
      "title" :"إذاعة القرآن الكريم 📻",
      "content" : "استمع إلى إذاعة القرآن الكريم المصرية والسعودية في أي وقت وأي مكان… لتعيش مع القرآن طول يومك."
    },
    {
      "title" :"بحث 🔎",
      "content" : "ابحث بسرعة عن أي سورة أو آية تريدها… وابدأ القراءة فورًا بدون تعب."
    },
    {
      "title" :"مقاطع الفيديو 🎙️",
      "content" : "مكتبة كبيرة من بودكاست ومحتوى إسلامي مفيد يساعدك على التعلم والتطوير والاستفادة يوميًا."
    },
    {
      "title" :"الوِرد اليومي 📅",
      "content" : "ضع هدفًا لختم القرآن، وحدد وردك اليومي… والتطبيق سيحسب لك كم تقرأ يوميًا حتى تصل لهدفك بإذن الله."
    },
    {
      "title" :"الإعدادات ⚙️",
      "content" : "تحكم في الثيم (داكن/فاتح/ذهبي)، واللغة، والإشعارات… وخصّص التطبيق بالشكل الذي تحبه."
    },
  ];

  @override
  Future<void> close() async {
    closeCoach();
    homeScrollController.dispose();
    await super.close();
  }
  // Mock data for grid items
  final List<Map<String, String>> gridItems = [
    {"image": "assets/images/prayer_times.png", "title": "توقيت الصلاة"},
    {"image": "assets/images/quran.png", "title": "القرآن الكريم"},
    {"image": "assets/images/hadith.png", "title": "احاديث نبوية"},
    {"image": "assets/images/prays.png", "title": "ادعية واذكار"},
    {"image": "assets/images/hadith2.png", "title": "احاديث"},
    {"image": "assets/images/wodoo.png", "title": "تعليم الوضوء"},
    {"image": "assets/images/pray_teaching.png", "title": "تعليم الصلاة"},
    {"image": "assets/images/qiblah.png", "title": "تحديد القبلة"},
    {"image": "assets/images/masjed.png", "title": "مساجد"},
    {"image": "assets/images/ramadan.png", "title": "شهر رمضان"},
    {"image": "assets/images/haj.png", "title": "مناسك الحج والعمرة"},
    {"image": "assets/images/tasbeeh.png", "title": "السبحة"},
    {"image": "assets/images/zakah.png", "title": "حساب زكاة المال"},
    {"image": "assets/images/radio.png", "title": "اذاعة القرآن الكريم"},
    // {"image": "assets/images/search.png", "title": "بحث"},
    {"image": "assets/images/podcast.png", "title": "مقاطع الفيديو"},
    {"image": "assets/images/holy.png", "title": "الوِرد"},
    // {"image": "assets/images/podcast.png", "title": "admin"},
  ];

  void navigateToFeature(BuildContext context, int index, bool isDark) {
    // ✅ Close tutorial when navigating
    if (tutorialRunning) {
      closeCoach();
      finishTutorial();
    }

    switch (index) {
      case 0:
        navigateTo(context, PrayerTimesScreen());
        break;
      case 1:
        navigateTo(context, QuranMainScreen());
        break;
      case 2:
        navigateTo(context, OnePrayScreen(
          title: "ادعية نبوية",
          items: AzkarConstants.adeyahNabaweyah,
          isDark: isDark,
        ));
        break;
      case 3:
        AzkarCubit.get(context).getZekrBasedOnTime(context);
        navigateTo(context, AzkarScreen());
        break;
      case 4:
        navigateTo(context, HadithScreen());
        break;
      case 5:
        navigateTo(context, WodooInstructionsScreen());
        break;
      case 6:
        navigateTo(context, PrayInstructionsScreen());
        break;
      case 7:
        navigateTo(context, QiblahOnBoardingScreen());
        break;
      case 8:
        navigateTo(context, MosqueLocationScreen());
        break;
      case 9:
        navigateTo(context, RamadanHome());
        break;
      case 10:
        navigateTo(context, OmrahScreen(isDark: isDark));
        break;
      case 11:
        navigateTo(context, TasbeehScreen());
        break;
      case 12:
        navigateTo(context, ZakahCalculator());
        break;
      case 13:
        navigateTo(context, QuranRadioScreen());
        break;
      // case 14:
      //   navigateTo(context, SearchScreen());
      //   break;
      case 14:
        navigateTo(context, PodcastsScreen());
        break;
      case 15:
        navigateTo(context, RecitationScreen());
        break;

      // case 17:
      //   navigateTo(context, AdminAddChallengeScreen());
      //   break;
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
