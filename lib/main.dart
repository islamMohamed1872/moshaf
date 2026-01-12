import 'dart:async';
import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as ln;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:home_widget/home_widget.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/controllers/auth/auth_cubit.dart';
import 'package:moshaf/controllers/daily_challenge/daily_challenge_cubit.dart';
import 'package:moshaf/controllers/home/home_cubit.dart';
import 'package:moshaf/controllers/leaderboard/leaderboard_cubit.dart';
import 'package:moshaf/controllers/qiblah/qiblah_cubit.dart';
import 'package:moshaf/controllers/settings/settings_cubit.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';
import 'package:moshaf/controllers/quran_audio/audio_quran_cubit.dart';
import 'package:moshaf/controllers/azkar/azkar_cubit.dart';
import 'package:moshaf/controllers/prayer_times/prayer_times_cubit.dart';
import 'package:moshaf/controllers/text_quran/text_quran_cubit.dart';
import 'package:moshaf/network/dio_helper.dart';
import 'package:moshaf/views/home/home_screen.dart';
import 'package:moshaf/views/landing/landing_screen.dart';
import 'package:quran/quran.dart' as quran;
import 'package:workmanager/workmanager.dart';
import 'components/cache_helper.dart';
import 'components/overaly.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'controllers/recitation/recitation_cubit.dart';
import 'firebase_options.dart';


// ================================================
// WORKMANAGER CALLBACKS (iOS)
// ================================================

@pragma('vm:entry-point')
Future<void> callbackFetchPrayerTimes() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('ar', null);
    DioHelper.init();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(tz.local.name));
    final cubit = PrayerTimesCubit();
    await cubit.fetchPrayerTimesNoInternet();
    await cubit.close();
    print("✅ iOS: Prayer times fetched via WorkManager");
  } catch (e) {
    print("❌ iOS: Error fetching prayer times: $e");
  }
}

@pragma('vm:entry-point')
Future<void> callbackCheckQuranReminder() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final String? lastReadStr = await CacheHelper.getData(key: 'lastRead');

    if (lastReadStr == null) {
      return;
    }

    DateTime? lastRead;
    try {
      lastRead = DateTime.parse(lastReadStr);
    } catch (_) {
      return;
    }

    final now = DateTime.now();
    final difference = now.difference(lastRead).inDays;

    if (difference >= 2) {
      final List? skipped = await CacheHelper.getData(key: 'mutedNotifications');
      if (skipped?.contains("تذكير بالمصحف") ?? false) return;

      final int? lastSora = await CacheHelper.getData(key: 'sora');
      if(lastSora == null) return;
      final String sorahName =quran.getSurahNameArabic(lastSora);
      final iOSDetails = ln.DarwinNotificationDetails();
      final notifDetails = ln.NotificationDetails(iOS: iOSDetails);

      await flutterLocalNotificationsPlugin.show(
        10,
        "لا تكن هاجراً للقرآن",
        "تذكير بقراءة سورة $sorahName",
        notifDetails,
      );

      print("✅ iOS: Quran reminder notification sent");
    }
  } catch (e, st) {
    print('❌ iOS: checkAndFireQuranReminder error: $e\n$st');
  }
}

Future<void> ensureLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    permission = await Geolocator.requestPermission();
  }
}

@pragma('vm:entry-point')
void fetchPrayerTimesAlarm() async {
  WidgetsFlutterBinding.ensureInitialized();

  try{
    await initializeDateFormatting('ar', null);
    DioHelper.init();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(tz.local.name));
    final cubit = PrayerTimesCubit();
    await cubit.fetchPrayerTimesNoInternet();
    // await cubit.scheduleDoaaNotifications();
    await cubit.close();
  }
  catch(e){
    print(e);
  }

}

@pragma('vm:entry-point')
Future<void> checkAndFireQuranReminder() async {
  try {
    // read saved lastRead datetime string
    final String? lastReadStr = await CacheHelper.getData(key: 'lastRead');

    if (lastReadStr == null) {
      // nothing read yet — nothing to remind
      return;
    }

    DateTime? lastRead;
    try {
      lastRead = DateTime.parse(lastReadStr);
    } catch (_) {
      // if parsing fails, bail out
      return;
    }

    final now = DateTime.now();
    final difference = now.difference(lastRead).inDays;

    // Only proceed if 2 or more full days passed
    if (difference >= 2) {
      // make sure user didn't mute this notification
      final List? skipped = await CacheHelper.getData(key: 'mutedNotifications');
      if (skipped?.contains("تذكير بالمصحف") ?? false) return;

      // get last-read surah number (you earlier used key "sora" — ensure name matches)
      final int? lastSora = await CacheHelper.getData(key: 'sora');

      if(lastSora == null) return;

      // get surah name safely
      final String sorahName = quran.getSurahNameArabic(lastSora);

      // call your notification helper (see below)
      final androidDetails = ln.AndroidNotificationDetails(
        'quran_channel',
        'Quran Notifications',
        channelDescription: 'Quran reading reminder',
        importance: ln.Importance.max,
        priority: ln.Priority.high,
        playSound: true,
      );

      final notifDetails = ln.NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        10, // id
        "لا تكن هاجراً للقرآن",
        "تذكير بقراءة سورة $sorahName",
        notifDetails,
      );

    }
  } catch (e, st) {
    // optionally log
    print('checkAndFireQuranReminder error: $e\n$st');
  }
}

Future<void> scheduleDailyQuranCheck() async {
  // A one-shot: run in 1 minute for an initial quick check (optional)
  final DateTime oneShotTime = DateTime.now().add(const Duration(minutes: 1));
  await AndroidAlarmManager.oneShotAt(
    oneShotTime,
    // unique id for this job
    3,
    checkAndFireQuranReminder,
    exact: true,
    wakeup: true,
    allowWhileIdle: true,
  );

  // periodic: run every day
  await AndroidAlarmManager.periodic(
    const Duration(days: 1),
    // unique id for periodic job (must be different from oneShot id)
    2,
    checkAndFireQuranReminder,
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
    allowWhileIdle: true,
  );

  print('Alarm scheduled for daily Quran check.');
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == "fetchPrayerTimes") {
        print("🔔 WorkManager: Executing fetchPrayerTimes");
        await callbackFetchPrayerTimes();
      } else if (task == "quranReminder") {
        print("🔔 WorkManager: Executing quranReminder");
        await callbackCheckQuranReminder();
      }
      return true;
    } catch (e) {
      print("❌ WorkManager task error: $e");
      return false;
    }
  });
}

/// Local notifications plugin instance (global)
final ln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
ln.FlutterLocalNotificationsPlugin();

/// Calculate initial delay to run at specific time (hour:minute)
Duration _calculateInitialDelay(int targetHour, int targetMinute) {
  final now = DateTime.now();
  var scheduledTime = DateTime(now.year, now.month, now.day, targetHour, targetMinute);

  // If the time has already passed today, schedule for tomorrow
  if (scheduledTime.isBefore(now)) {
    scheduledTime = scheduledTime.add(const Duration(days: 1));
  }

  final delay = scheduledTime.difference(now);
  print("⏰ Initial delay calculated: ${delay.inHours}h ${delay.inMinutes % 60}m until $targetHour:${targetMinute.toString().padLeft(2, '0')}");
  return delay;
}


/// ================================================
/// MAIN ENTRY POINT
/// ================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final androidPlugin =
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      ln.AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestNotificationsPermission();

  await androidPlugin?.requestExactAlarmsPermission();

  await dotenv.load(fileName: ".env");
  // print("📦 GOOGLE_MAPS_API_KEY = ${dotenv.env['GOOGLE_MAPS_API_KEY']}");
  await ensureLocationPermission();
  callbackCheckQuranReminder();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
if(Platform.isAndroid){
  await AndroidAlarmManager.initialize();
  await scheduleDailyQuranCheck();
  final now = DateTime.now();
  DateTime nextMidnight = DateTime(now.year, now.month, now.day, 0, 1);

  if (nextMidnight.isBefore(now)) {
    // already passed midnight — schedule for next day
    nextMidnight = nextMidnight.add(const Duration(days: 1));
  }
  await AndroidAlarmManager.oneShotAt(nextMidnight, 0, fetchPrayerTimesAlarm, exact: true, wakeup: true,);
  await AndroidAlarmManager.periodic(const Duration(days: 1), 1, fetchPrayerTimesAlarm, exact: true, wakeup: true,rescheduleOnReboot: true);
}
else if (Platform.isIOS) {
  // 🔹 Initialize WorkManager for iOS
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // 🔹 Schedule periodic prayer times fetch (every 1 day)
  await Workmanager().registerPeriodicTask(
    "ios_fetch_prayer_times",
    "fetchPrayerTimes",
    frequency: const Duration(days: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    initialDelay: _calculateInitialDelay(0, 1), // 00:01
    constraints: Constraints(
      requiresDeviceIdle: false,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresStorageNotLow: false,
      networkType: NetworkType.connected
    ),
  );

  // 🔹 Schedule daily Quran reminder check (every 1 day)
  await Workmanager().registerPeriodicTask(
    "ios_quran_reminder",
    "quranReminder",
    frequency: const Duration(days: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    initialDelay: _calculateInitialDelay(0, 1), // 00:01
    constraints: Constraints(
      requiresDeviceIdle: false,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresStorageNotLow: false,
        networkType: NetworkType.connected
    ),
  );

  print("📱 iOS: WorkManager tasks scheduled");

  HomeWidget.setAppGroupId('group.com.example.mostakeem');
}
  DioHelper.init();
  // Setup timezone info
  tz.initializeTimeZones();
  final String localTimeZone = tz.local.name;
  tz.setLocalLocation(tz.getLocation(localTimeZone));

  // Initialize JustAudio background (used for Adhan playback even in background)
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.yourapp.audio',
    androidNotificationChannelName: 'Quran Player',
    androidNotificationOngoing: true,
  );

  // Initialize the background service for overlay logic
  await initializeService();

  const androidInit = ln.AndroidInitializationSettings('@mipmap/ic_launcher');
  const iOSInit = ln.DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  const initSettings = ln.InitializationSettings(
    android: androidInit,
    iOS: iOSInit,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Ensure correct screen size metrics (needed for ScreenUtil)
  await ScreenUtil.ensureScreenSize();

  // Force portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set transparent status bar for cleaner look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialize date formatting for Arabic locale
  initializeDateFormatting('ar', null);

  // Start the app
  runApp(
    EasyLocalization(
    supportedLocales: [Locale('en'), Locale('ar')],
    path: 'assets/langs',
    fallbackLocale: Locale('ar'),
    startLocale: Locale('ar'),
    child: const MyApp(),
  ),
  );
}

/// ================================================
/// BACKGROUND SERVICE INITIALIZATION
/// ================================================
Future<void> initializeService() async {
  try {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart, // Function to run when service starts
        isForegroundMode: false,
        autoStart: true,
      ),
      iosConfiguration: IosConfiguration(),
    );

    service.startService();
  } catch (e) {
    print('Background service error: $e');
  }
}

/// ================================================
/// OVERLAY APP ENTRY POINT (used when showing overlay)
/// ================================================
@pragma("vm:entry-point")
void overlayMain() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ScreenUtilInit(
      designSize: const Size(392.72727272727275, 800.7272727272727),
      child: BlocProvider(
        create: (context) => HomeCubit()..getRandomAthkar(),
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: OverlayAthkarWidget(),
        ),
      ),
    ),
  );
}

/// ================================================
/// BACKGROUND SERVICE EXECUTION LOOP
/// ================================================
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  Timer? periodicTimer;

  if (service is AndroidServiceInstance) {
    // Stop service if requested
    service.on('stopService').listen((event) {
      periodicTimer?.cancel();
      service.stopSelf();
    });
  }

  // Periodically show overlay every 15 minutes
  periodicTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
    try {
      if (service is AndroidServiceInstance) {
        if (await FlutterOverlayWindow.isPermissionGranted()) {
          if (await FlutterOverlayWindow.isActive()) {
            await FlutterOverlayWindow.closeOverlay();
          }

          // Show overlay widget
          await FlutterOverlayWindow.showOverlay(
            enableDrag: false,
            flag: OverlayFlag.clickThrough,
            alignment: OverlayAlignment.centerRight,
            visibility: NotificationVisibility.visibilityPublic,
          );

          // Auto close overlay after 5 seconds
          Future.delayed(const Duration(seconds: 5), () async {
            if (await FlutterOverlayWindow.isActive()) {
              await FlutterOverlayWindow.closeOverlay();
            }
          });
        }
      }
    } catch (e) {
      print('Overlay show error: $e');
    }
  });

}

/// ================================================
/// MAIN APP WIDGET
/// ================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(392.72727272727275, 800.7272727272727),
      child: MultiBlocProvider(
        providers: [
          BlocProvider( create: (context) => PrayerTimesCubit()..fetchPrayerTimesNoInternet()),
          BlocProvider(create: (context) => HomeCubit()..requestLocationOnce()..requestOverlay()..getFirstTime(),lazy: false,),
          BlocProvider(create: (context) => TextQuranCubit()..loadJsonAsset()..getLastRead()..warmUpFontsOnAppStart(1)),
          BlocProvider(create: (context) => SettingsCubit()..getNotificationsState()),
          BlocProvider(create: (context) => ThemeCubit()..getThemeMode(),lazy: false,),
          BlocProvider(create: (context) => QiblahCubit()),
          BlocProvider(create: (context) => LeaderboardCubit()),
          BlocProvider(create: (context) => DailyChallengeCubit()),
          BlocProvider(create: (context) => RecitationCubit()..initializeRecitation()..loadJsonAsset()),
          BlocProvider(create: (context) => AuthCubit()),
          BlocProvider(create: (context) => AzkarCubit()),
          BlocProvider(create: (context) => AudioQuranCubit()..loadReciters()),
        ],
        child: BlocBuilder<ThemeCubit,ThemeMode>(
           builder: (context, themeMode) => MaterialApp(
             locale: context.locale,
             supportedLocales: context.supportedLocales,
             localizationsDelegates: context.localizationDelegates,
             title: 'Mostakeem',
             debugShowCheckedModeBanner: false,
             themeMode: themeMode,
             theme: ThemeData(
               brightness: AppColors.isGoldMode ? Brightness.light : Brightness.light,
               scaffoldBackgroundColor: AppColors.isGoldMode
                   ? const Color(AppColors.goldBackground)
                   : Colors.white,
               primaryColor: AppColors.isGoldMode
                   ? const Color(AppColors.goldPrimary)
                   : const Color(AppColors.mainGreen),
               textTheme: TextTheme(
                 bodyMedium: TextStyle(
                   color: AppColors.isGoldMode
                       ? const Color(AppColors.goldText)
                       : Colors.black,
                 ),
               ),
             ),
             darkTheme: ThemeData(
               scaffoldBackgroundColor: const Color(0xFF151515),
               appBarTheme: const AppBarTheme(
                 backgroundColor: Colors.white,
                 systemOverlayStyle: SystemUiOverlayStyle(
                   statusBarColor: Colors.white, // same as scaffold for smoothness
                   statusBarIconBrightness: Brightness.light, // dark icons on light bg
                   statusBarBrightness: Brightness.light, // for iOS
                 ),
               ),

             ),
             // home: const AppLayout(),
             home:FirebaseAuth.instance.currentUser==null? LandingScreen():HomeScreen(),
           ),
        ),
      ),
    );
  }


}
