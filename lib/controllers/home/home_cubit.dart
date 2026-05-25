import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
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
import 'package:moshaf/views/haj_and_omrah/haj_screen.dart';
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
import 'package:moshaf/views/rafeq/rafeq_intro_screen.dart';
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
import '../../views/habit_tracker/habit_tracker_screen.dart';
import '../../views/rafeq/rafeq_screen.dart';
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
  final ScrollController scrollController = ScrollController();
  void autoScroll() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (!scrollController.hasClients) return;

      final maxScroll = scrollController.position.maxScrollExtent;
      final current = scrollController.offset;

      double nextOffset = current + 220;

      if (nextOffset >= maxScroll) {
        nextOffset = 0;
        await scrollController.animateTo(
          nextOffset,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
        return;
      }

      await scrollController.animateTo(
        nextOffset,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );

      autoScroll();
    });
  }
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

  final List<Map<String, String>> coachContent = [
    {
      "title": "مواعيد الصلاة 🕌",
      "content": "هنا ستجد الصلاة القادمة، الوقت المتبقي لها، التاريخ الهجري والميلادي، ومتابعة يومك حول أوقات الصلاة."
    },
    {
      "title": "رفيقك اليومي 🤖",
      "content": "رفيق يعرض لك تذكيرات ذكية حسب الوقت: أذكار، صلاة قريبة، ورد يومي، أو تنبيه يساعدك تكمل يومك بروح أفضل."
    },
    {
      "title": "ذكر اليوم ✨",
      "content": "هنا يظهر لك ذكر عشوائي متجدد. اضغط على زر التحديث للحصول على ذكر جديد في أي وقت."
    },
    {
      "title": "القرآن الكريم 📖",
      "content": "اقرأ القرآن الكريم، تابع آخر موضع قراءة، واستمتع بتجربة قراءة منظمة وسهلة."
    },
    {
      "title": "أدعية وأذكار 🤲",
      "content": "موسوعة للأذكار والأدعية اليومية مثل أذكار الصباح والمساء، أذكار الصلاة، وأدعية متنوعة."
    },
    {
      "title": "أحاديث نبوية ﷺ",
      "content": "مجموعة أحاديث مختارة تساعدك تتعلم من سنة النبي ﷺ وتعيش مع معانيها يوميًا."
    },
    {
      "title": "توقيت الصلاة ⏳",
      "content": "اعرف مواقيت الصلوات كاملة حسب موقعك، مع متابعة الصلاة القادمة والوقت المتبقي لها."
    },
    {
      "title": "إذاعة القرآن الكريم 📻",
      "content": "استمع إلى إذاعات القرآن الكريم في أي وقت لتبقى قريبًا من القرآن خلال يومك."
    },
    {
      "title": "مناسك الحج والعمرة 🕋",
      "content": "تعرف على خطوات الحج والعمرة بشكل مرتب وواضح يساعدك على فهم المناسك بسهولة."
    },
    {
      "title": "السبحة ✨",
      "content": "سبحة إلكترونية سهلة الاستخدام، يمكنك من خلالها عدّ الأذكار والتسبيح يوميًا."
    },
    {
      "title": "أدعية نبوية 🌿",
      "content": "مجموعة من الأدعية النبوية المختارة لتستخدمها في يومك وتتعلم معاني الدعاء."
    },
    {
      "title": "الوِرد اليومي 📅",
      "content": "حدد هدفك في قراءة القرآن، والتطبيق يساعدك تعرف كم تقرأ يوميًا حتى تصل لهدفك بإذن الله."
    },
    {
      "title": "تعليم الوضوء 💧",
      "content": "شرح مبسط لتعليم الوضوء خطوة بخطوة بطريقة واضحة وسهلة."
    },
    {
      "title": "تعليم الصلاة 🧎‍♂️",
      "content": "تعلم خطوات الصلاة بطريقة منظمة ومبسطة، مناسبة للكبار والأطفال."
    },
    {
      "title": "تحديد القبلة 🧭",
      "content": "اعرف اتجاه القبلة أينما كنت لتصلي بثقة واطمئنان."
    },
    {
      "title": "مساجد قريبة 🕌📍",
      "content": "ابحث عن أقرب المساجد حولك بسهولة باستخدام موقعك الحالي."
    },
    {
      "title": "شهر رمضان 🌙",
      "content": "قسم خاص بتجربة رمضان، يشمل محتوى وتجهيزات تساعدك في الشهر الكريم."
    },
    {
      "title": "حساب زكاة المال 💰",
      "content": "احسب زكاتك بطريقة سهلة ومنظمة لمعرفة المقدار المستحق بإذن الله."
    },
    {
      "title": "مقاطع الفيديو 🎙️",
      "content": "مكتبة محتوى مرئي وبودكاست إسلامي مفيد للتعلم والاستفادة اليومية."
    },
    {
      "title": "رفيق 🤖",
      "content": "ادخل إلى تجربة رفيق، مساعدك الذكي داخل التطبيق للتذكير والمتابعة والدعم اليومي."
    },
    {
      "title": "أسماء الله الحسنى ✦",
      "content": "تعرف كل مرة على اسم من أسماء الله الحسنى ومعناه بطريقة جميلة وسهلة."
    },
    {
      "title": "الإعدادات ⚙️",
      "content": "من هنا يمكنك تغيير الثيم، اللغة، الإشعارات، وخصائص التطبيق حسب تفضيلك."
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
    {"image": "assets/images/quran.png", "title": "القرآن الكريم"},
    {"image": "assets/images/prays.png", "title": "ادعية واذكار"},
    {"image": "assets/images/hadith2.png", "title": "احاديث"},
    {"image": "assets/images/prayer_times.png", "title": "توقيت الصلاة"},
    {"image": "assets/images/radio.png", "title": "اذاعة القرآن الكريم"},
    {"image": "assets/images/haj.png", "title": "مناسك الحج والعمرة"},
    {"image": "assets/images/tasbeeh.png", "title": "السبحة"},
    {"image": "assets/images/hadith.png", "title": "ادعية نبوية"},
    {"image": "assets/images/holy.png", "title": "الوِرد"},
    {"image": "assets/images/wodoo.png", "title": "تعليم الوضوء"},
    {"image": "assets/images/pray_teaching.png", "title": "تعليم الصلاة"},
    {"image": "assets/images/qiblah.png", "title": "تحديد القبلة"},
    {"image": "assets/images/masjed.png", "title": "مساجد"},
    {"image": "assets/images/ramadan.png", "title": "شهر رمضان"},
    {"image": "assets/images/zakah.png", "title": "حساب زكاة المال"},
    {"image": "assets/images/podcast.png", "title": "مقاطع الفيديو"},
    {"image": "assets/images/rafeq_pray.png", "title": "رفيق"},
    {"image": "assets/images/habit_tracker.png", "title": "متابعة العادات"},
  ];

  void navigateToFeature(BuildContext context, int index, bool isDark) {
    // ✅ Close tutorial when navigating
    if (tutorialRunning) {
      closeCoach();
      finishTutorial();
    }

    switch (index) {
      case 0:
        navigateTo(context, QuranMainScreen());
        break;
      case 1:
        AzkarCubit.get(context).getZekrBasedOnTime(context);
        navigateTo(context, AzkarScreen());
        break;
      case 2:
        navigateTo(context, HadithScreen());
        break;
      case 3:
        navigateTo(context, PrayerTimesScreen());
        break;
      case 4:
        navigateTo(context, QuranRadioScreen());
        break;
      case 5:
        navigateTo(context, HajScreen(isDark: isDark));
        break;
      case 6:
        navigateTo(context, TasbeehScreen());
        break;
      case 7:
        navigateTo(context, OnePrayScreen(
          title: "ادعية نبوية",
          items: AzkarConstants.adeyahNabaweyah,
          // isDark: isDark,
        ));
        break;
      case 8:
        navigateTo(context, RecitationScreen());
        break;
      case 9:
        navigateTo(context, WodooInstructionsScreen());
        break;
      case 10:
        navigateTo(context, PrayInstructionsScreen());
        break;
      case 11:
        navigateTo(context, QiblahOnBoardingScreen());
        break;
      case 12:
        navigateTo(context, MosqueLocationScreen());
        break;
      case 13:
        navigateTo(context, RamadanScreen());
        break;
      // case 14:
      //   navigateTo(context, SearchScreen());
      //   break;
      case 14:
        navigateTo(context, ZakahCalculator());
        break;
      case 15:
        navigateTo(context, PodcastsScreen());
        break;
      case 16:
        navigateTo(context, const RafeqIntroScreen());
      case 17:
        navigateTo(context, const HabitTrackerScreen());
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


  // String athkar = "";
  String currentZekr = '';

  /// Picks a random zekr from the JSON asset and emits a rebuild.
  Future<void> loadRandomZekr() async {
    emit(ZekrLoadingState());
    currentZekr = '';

    try {
      final data = await rootBundle.loadString('assets/json/athkar.json');
      final List<dynamic> list = json.decode(data);
      final random = Random();
      currentZekr = list[random.nextInt(list.length)] as String;
    } catch (_) {
      currentZekr = 'سبحان الله وبحمده سبحان الله العظيم';
    }
    print("object");
    emit(ZekrLoadedState());
  }
  Future<String> getRandomAthkar() async {
    await loadRandomZekr();
    return currentZekr;
  }

  Map<String, String>? currentAllahName;

  void loadRandomAllahName() {
    emit(AllahNameLoadingState());
    final list = AzkarConstants.asmaaAllahAlHusna; // your existing constant
    final random = Random();
    currentAllahName = list[random.nextInt(list.length)];
    emit(AllahNameLoadedState());
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

      // print('✅ Location cached: (${pos.latitude}, ${pos.longitude})');

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

  bool showFloatingRafeq = true;

  Future<void> loadRafeqVisibility() async {
    showFloatingRafeq = await CacheHelper.getData(key: 'showFloatingRafeq') ?? true;
    emit(RafeqVisibilityChanged());
  }

  Future<void> toggleRafeqVisibility() async {
    showFloatingRafeq = !showFloatingRafeq;
    await CacheHelper.saveData(key: 'showFloatingRafeq', value: showFloatingRafeq);
    emit(RafeqVisibilityChanged());
  }


  Map<String, dynamic>? currentDailyAyah;
  Map<String, dynamic>? currentDailyHadith;

  String _todayKey() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  final List<Map<String, String>> _dailyHadithList = [
    {
      'hadith': 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى، فَمَنْ كَانَتْ هِجْرَتُهُ إِلَى اللَّهِ وَرَسُولِهِ فَهِجْرَتُهُ إِلَى اللَّهِ وَرَسُولِهِ، وَمَنْ كَانَتْ هِجْرَتُهُ لِدُنْيَا يُصِيبُهَا أَوِ امْرَأَةٍ يَنْكِحُهَا فَهِجْرَتُهُ إِلَى مَا هَاجَرَ إِلَيْهِ.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'الدِّينُ النَّصِيحَةُ. قُلْنَا: لِمَنْ؟ قَالَ: لِلَّهِ، وَلِكِتَابِهِ، وَلِرَسُولِهِ، وَلِأَئِمَّةِ الْمُسْلِمِينَ وَعَامَّتِهِمْ.',
      'source': 'رواه مسلم',
    },
    {
      'hadith': 'لا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ، وَمَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيُكْرِمْ جَارَهُ، وَمَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيُكْرِمْ ضَيْفَهُ.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ، وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا، وَخَالِقِ النَّاسَ بِخُلُقٍ حَسَنٍ.',
      'source': 'رواه الترمذي',
    },
    {
      'hadith': 'الطُّهُورُ شَطْرُ الإِيمَانِ، وَالْحَمْدُ لِلَّهِ تَمْلأُ الْمِيزَانَ، وَسُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ تَمْلآنِ أَوْ تَمْلأُ مَا بَيْنَ السَّمَاوَاتِ وَالأَرْضِ.',
      'source': 'رواه مسلم',
    },
    {
      'hadith': 'مَنْ دَلَّ عَلَى خَيْرٍ فَلَهُ مِثْلُ أَجْرِ فَاعِلِهِ.',
      'source': 'رواه مسلم',
    },
    {
      'hadith': 'خَيْرُكُمْ مَنْ تَعَلَّمَ القُرْآنَ وَعَلَّمَهُ.',
      'source': 'رواه البخاري',
    },
    {
      'hadith': 'الرَّاحِمُونَ يَرْحَمُهُمُ الرَّحْمَنُ، ارْحَمُوا مَنْ فِي الأَرْضِ يَرْحَمْكُمْ مَنْ فِي السَّمَاءِ.',
      'source': 'رواه الترمذي',
    },
    {
      'hadith': 'البِرُّ حُسْنُ الخُلُقِ، وَالإِثْمُ مَا حَاكَ فِي صَدْرِكَ وَكَرِهْتَ أَنْ يَطَّلِعَ عَلَيْهِ النَّاسُ.',
      'source': 'رواه مسلم',
    },
    {
      'hadith': 'يَسِّرُوا وَلَا تُعَسِّرُوا، وَبَشِّرُوا وَلَا تُنَفِّرُوا.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'أَحَبُّ الأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ، وَأَمْرُكَ بِالْمَعْرُوفِ وَنَهْيُكَ عَنِ الْمُنْكَرِ صَدَقَةٌ.',
      'source': 'رواه الترمذي',
    },
    {
      'hadith': 'مَنْ لَا يَرْحَمْ النَّاسَ لَا يَرْحَمْهُ اللَّهُ.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'الكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'إِنَّ اللَّهَ جَمِيلٌ يُحِبُّ الجَمَالَ، الكِبْرُ بَطَرُ الحَقِّ وَغَمْطُ النَّاسِ.',
      'source': 'رواه مسلم',
    },
    {
      'hadith': 'المُسْلِمُ مَنْ سَلِمَ المُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ، وَالمُهَاجِرُ مَنْ هَجَرَ مَا نَهَى اللَّهُ عَنْهُ.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'الدُّعَاءُ هُوَ العِبَادَةُ.',
      'source': 'رواه الترمذي وصححه الألباني',
    },
    {
      'hadith': 'اسْتَعِنْ بِاللَّهِ وَلَا تَعْجِزْ، وَإِنْ أَصَابَكَ شَيْءٌ فَلَا تَقُلْ: لَوْ أَنِّي فَعَلْتُ كَانَ كَذَا وَكَذَا، وَلَكِنْ قُلْ: قَدَرُ اللَّهِ وَمَا شَاءَ فَعَلَ.',
      'source': 'رواه مسلم',
    },
    {
      'hadith': 'إِنَّ مِنْ خِيَارِكُمْ أَحْسَنَكُمْ أَخْلَاقًا.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'مَنْ غَشَّ فَلَيْسَ مِنَّا.',
      'source': 'رواه مسلم',
    },
    {
      'hadith': 'لَا تَغْضَبْ. فَرَدَّدَ مِرَارًا، قَالَ: لَا تَغْضَبْ.',
      'source': 'رواه البخاري',
    },
    {
      'hadith': 'المَرْءُ مَعَ مَنْ أَحَبَّ.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'الْيَدُ العُلْيَا خَيْرٌ مِنَ الْيَدِ السُّفْلَى، وَابْدَأْ بِمَنْ تَعُولُ.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'خَيْرُ النَّاسِ أَنْفَعُهُمْ لِلنَّاسِ.',
      'source': 'رواه الطبراني وحسنه الألباني',
    },
    {
      'hadith': 'الصِّدْقُ يَهْدِي إِلَى البِرِّ، وَإِنَّ البِرَّ يَهْدِي إِلَى الجَنَّةِ، وَإِنَّ الرَّجُلَ لَيَصْدُقُ حَتَّى يُكْتَبَ عِنْدَ اللَّهِ صِدِّيقًا.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الغَضَبِ.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'مَنْ سَتَرَ مُسْلِمًا سَتَرَهُ اللَّهُ فِي الدُّنْيَا وَالآخِرَةِ.',
      'source': 'رواه مسلم',
    },
    {
      'hadith': 'إِنَّ اللَّهَ رَفِيقٌ يُحِبُّ الرِّفْقَ فِي الأَمْرِ كُلِّهِ.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ، وَمَا زَادَ اللَّهُ عَبْدًا بِعَفْوٍ إِلَّا عِزًّا.',
      'source': 'رواه مسلم',
    },
    {
      'hadith': 'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الجَنَّةِ.',
      'source': 'رواه مسلم',
    },
    {
      'hadith': 'مَنْ قَرَأَ حَرْفًا مِنْ كِتَابِ اللَّهِ فَلَهُ بِهِ حَسَنَةٌ، وَالحَسَنَةُ بِعَشْرِ أَمْثَالِهَا.',
      'source': 'رواه الترمذي',
    },
    {
      'hadith': 'الْحَيَاءُ لَا يَأْتِي إِلَّا بِخَيْرٍ.',
      'source': 'متفق عليه',
    },
    {
      'hadith': 'مَنْ نَفَّسَ عَنْ مُؤْمِنٍ كُرْبَةً مِنْ كُرَبِ الدُّنْيَا نَفَّسَ اللَّهُ عَنْهُ كُرْبَةً مِنْ كُرَبِ يَوْمِ القِيَامَةِ.',
      'source': 'رواه مسلم',
    },
  ];

  Future<void> loadDailyAyah() async {
    emit(DailyAyahLoadingState());

    final today = _todayKey();
    final cached = await CacheHelper.getData(key: 'daily_ayah');

    if (cached != null) {
      try {
        final decoded = jsonDecode(cached);
        if (decoded['date'] == today) {
          currentDailyAyah = Map<String, dynamic>.from(decoded['data']);
          emit(DailyAyahLoadedState());
          return;
        }
      } catch (_) {}
    }

    final random = Random();

    final surahNumber = random.nextInt(114) + 1;
    final verseCount = quran.getVerseCount(surahNumber);
    final verseNumber = random.nextInt(verseCount) + 1;

    final ayah = {
      'surahNumber': surahNumber,
      'surahName': quran.getSurahNameArabic(surahNumber),
      'verseNumber': verseNumber,
      'text': quran.getVerse(
        surahNumber,
        verseNumber,
        verseEndSymbol: false,
      ),
    };

    currentDailyAyah = ayah;

    await CacheHelper.saveData(
      key: 'daily_ayah',
      value: jsonEncode({
        'date': today,
        'data': ayah,
      }),
    );

    emit(DailyAyahLoadedState());
  }

  Future<void> loadDailyHadith() async {
    emit(DailyHadithLoadingState());

    final today = _todayKey();
    final cached = await CacheHelper.getData(key: 'daily_hadith');

    if (cached != null) {
      try {
        final decoded = jsonDecode(cached);
        if (decoded['date'] == today) {
          currentDailyHadith = Map<String, dynamic>.from(decoded['data']);
          emit(DailyHadithLoadedState());
          return;
        }
      } catch (_) {}
    }

    final random = Random();
    final hadith = _dailyHadithList[random.nextInt(_dailyHadithList.length)];

    currentDailyHadith = hadith;

    await CacheHelper.saveData(
      key: 'daily_hadith',
      value: jsonEncode({
        'date': today,
        'data': hadith,
      }),
    );

    emit(DailyHadithLoadedState());
  }

  Future<void> refreshDailyAyah() async {
    await CacheHelper.deleteData(key: 'daily_ayah');
    await loadDailyAyah();
  }

  Future<void> refreshDailyHadith() async {
    await CacheHelper.deleteData(key: 'daily_hadith');
    await loadDailyHadith();
  }

}
