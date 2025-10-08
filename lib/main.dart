import 'dart:async';
import 'dart:convert';
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
import 'package:moshaf/modules/audio_quran/cubit/audio_quran_cubit.dart';
import 'package:moshaf/modules/azkar/cubit/azkar_cubit.dart';
import 'package:moshaf/modules/prayer_times/cubit/prayer_times_cubit.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'components/audio_service.dart';
import 'components/overaly.dart';
import 'cubit/cubit.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'layout/app_layout.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Local notifications plugin instance (global)
final ln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
ln.FlutterLocalNotificationsPlugin();

/// ================================================
/// BACKGROUND TASK CALLBACK (runs in separate isolate)
/// ================================================
@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized(); // Needed for async code in background

  Workmanager().executeTask((task, inputData) async {
    try {
      // Handle only tasks registered with these names
      if (task == "fetchPrayerTimes" || task == "dailyPrayerTimesTask") {
        await initializeDateFormatting('ar', null);

        // Ensure timezone database is ready
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation(tz.local.name));

        // Create a new Cubit instance to fetch updated times
        final cubit = PrayerTimesCubit();
        await cubit.fetchPrayerTimes(); // Fetch and save to SharedPreferences
        await cubit.close();

        return Future.value(true); // Signal task success
      }

      return Future.value(true);
    } catch (e) {
      print('Workmanager error: $e');
      return Future.value(false);
    }
  });
}

/// ================================================
/// MAIN ENTRY POINT
/// ================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialize WorkManager (used for daily automatic fetch of prayer times)
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Clear old background jobs to avoid duplicates
  await Workmanager().cancelAll();

  // Register a periodic background task every 6 hours
  await Workmanager().registerPeriodicTask(
    "dailyPrayerTimesTask",
    "fetchPrayerTimes",
    frequency: const Duration(hours: 6), // Android’s min reliable interval
    constraints: Constraints(
      networkType: NetworkType.connected, // Only fetch if network is available
    ),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );

  // Setup local notifications (for showing prayer reminders)
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
  runApp(const MyApp());
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
            create: (context) {
              final cubit = PrayerTimesCubit();
              _initializePrayerTimes(cubit);
              return cubit;
            },
            lazy: false, // Fetch immediately on app start
          ),

          // Other cubits
          BlocProvider(create: (context) => AppCubit()..requestOverlay()),
          BlocProvider(create: (context) => TextQuranCubit()..loadJsonAsset()),
          BlocProvider(create: (context) => AzkarCubit()),
          BlocProvider(create: (context) => AudioQuranCubit()),
        ],
        child: MaterialApp(
          title: 'Mostakeem',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
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
          home: const AppLayout(),
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
