import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as ln;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';
import 'package:moshaf/modules/audio_quran/cubit/audio_quran_cubit.dart';
import 'package:moshaf/modules/azkar/cubit/azkar_cubit.dart';
import 'package:moshaf/modules/prayer_times/cubit/prayer_times_cubit.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_cubit.dart';
import 'package:moshaf/network/dio_helper.dart';
import 'package:moshaf/views/landing/landing_screen.dart';
import 'package:moshaf/views/prayer_times/prayer_times_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'components/audio_service.dart';
import 'components/overaly.dart';
import 'cubit/cubit.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'layout/app_layout.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:package_info_plus/package_info_plus.dart';



@pragma('vm:entry-point')
void fetchPrayerTimesAlarm() async {
  WidgetsFlutterBinding.ensureInitialized();
  try{
    await initializeDateFormatting('ar', null);
    DioHelper.init();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(tz.local.name));
    final cubit = PrayerTimesCubit();
    await cubit.fetchPrayerTimes();
    await cubit.close();
  }
  catch(e){
    print(e);
  }

}

/// Local notifications plugin instance (global)
final ln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
ln.FlutterLocalNotificationsPlugin();


/// ================================================
/// MAIN ENTRY POINT
/// ================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
if(Platform.isAndroid){
  await AndroidAlarmManager.initialize();

  final now = DateTime.now();
  final next = DateTime(now.year, now.month, now.day, 0, 1).add(const Duration(days: 1));
  await AndroidAlarmManager.oneShotAt(next, 0, fetchPrayerTimesAlarm, exact: true, wakeup: true,);
  await AndroidAlarmManager.periodic(const Duration(days: 1), 1, fetchPrayerTimesAlarm, exact: true, wakeup: true,rescheduleOnReboot: true);
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
  runApp(EasyLocalization(
    supportedLocales: [Locale('en'), Locale('ar')],
    path: 'assets/langs',
    fallbackLocale: Locale('ar'),
    startLocale: Locale('ar'),
    child: MyApp(),
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
        isForegroundMode: true,
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
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ScreenUtilInit(
      designSize: const Size(392.72727272727275, 800.7272727272727),
      child: BlocProvider(
        create: (context) => AppCubit()..getRandomAthkar(),
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
          // PrayerTimesCubit – responsible for fetching and caching prayer times
          BlocProvider(
            create: (context) => PrayerTimesCubit()..fetchPrayerTimes(),),
          // Other cubits
          BlocProvider(create: (context) => AppCubit()..requestLocationPermissions()..requestOverlay()),
          BlocProvider(create: (context) => TextQuranCubit()..loadJsonAsset()),
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider(create: (context) => AzkarCubit()),
          BlocProvider(create: (context) => AudioQuranCubit()),
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
               brightness: Brightness.light,
               primarySwatch: Colors.blue,
               scaffoldBackgroundColor: HexColor("fffaf5"),
               bottomNavigationBarTheme: BottomNavigationBarThemeData(
                 type: BottomNavigationBarType.fixed,
                 backgroundColor: HexColor("fffaf5"),
                 elevation: 20.0,
                 selectedItemColor: HexColor("936f35"),
                 unselectedItemColor: HexColor("d6bb97"),
                 showUnselectedLabels: false,
               ),
             ),
             darkTheme: ThemeData(
               brightness: Brightness.dark,
               primarySwatch: Colors.blue,
               scaffoldBackgroundColor: Color(AppColors.scaffoldBg),
               bottomNavigationBarTheme: BottomNavigationBarThemeData(
                 type: BottomNavigationBarType.fixed,
                 backgroundColor: HexColor("1a1a1a"),
                 elevation: 20.0,
                 selectedItemColor: HexColor("ffd700"),
                 unselectedItemColor: HexColor("aaaaaa"),
                 showUnselectedLabels: false,
               ),
             ),
             // home: const AppLayout(),
             home: PrayerTimesScreen(),
           ),
        ),
      ),
    );
  }

  /// Initializes the cubit by fetching or loading cached prayer times
  Future<void> _initializePrayerTimes(PrayerTimesCubit cubit) async {
    if (await cubit.shouldFetchNewTimes()) {
      await cubit.fetchPrayerTimes(); // Fetch new times if outdated
    } else {
      await cubit.loadCachedPrayerTimes(); // Load from cache if still valid
    }
  }
}
