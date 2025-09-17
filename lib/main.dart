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
import 'package:moshaf/modules/audio_quran/cubit/audio_quran_cubit.dart';
import 'package:moshaf/modules/azkar/cubit/azkar_cubit.dart';
import 'package:moshaf/modules/prayer_times/cubit/prayer_times_cubit.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'components/overaly.dart';
import 'cubit/cubit.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'layout/app_layout.dart';

final ln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
ln.FlutterLocalNotificationsPlugin();
Future<void> main()async {

  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // change to false for release
  );
  await Workmanager().registerPeriodicTask(
    "checkPrayer",
    "checkPrayerTimes",
    frequency: const Duration(minutes: 15), // Android min = 15min
    inputData: {},
  );
  const androidInit = ln.AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = ln.InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  await ScreenUtil.ensureScreenSize();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // keep it transparent
      statusBarIconBrightness: Brightness.dark, // or Brightness.light based on background
      statusBarBrightness: Brightness.light, // for iOS
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  initializeDateFormatting('ar', null);
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(),
  );

  service.startService();
}

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


@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  Timer.periodic(const Duration(minutes: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await FlutterOverlayWindow.isPermissionGranted()) {
        // close any previous overlay before showing a new one
        if (await FlutterOverlayWindow.isActive()) {
          await FlutterOverlayWindow.closeOverlay();
        }

        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          flag: OverlayFlag.defaultFlag,
          alignment: OverlayAlignment.centerRight,
          visibility: NotificationVisibility.visibilityPublic,
        );

        Future.delayed(const Duration(seconds: 5), () async {
          await FlutterOverlayWindow.closeOverlay();
        });
      }
    }
  });
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "checkPrayerTimes") {
      final prefs = await SharedPreferences.getInstance();
      final timesMap = prefs.getString("cached_prayer_times");
      if (timesMap != null) {
        final Map<String, dynamic> times = jsonDecode(timesMap);
        final now = DateTime.now();

        for (final entry in times.entries) {
          final prayerName = entry.key; // fajr, dhuhr, asr...
          final prayerTime = DateTime.parse(entry.value);

          if ((prayerTime.difference(now)).inMinutes == 0) {
            // 🔔 Show notification
            const androidDetails = ln.AndroidNotificationDetails(
              'prayer_channel',
              'Prayer Times',
              channelDescription: 'Prayer time notifications',
              importance: ln.Importance.max,
              priority: ln.Priority.high,
              playSound: true,
            );
            const notifDetails = ln.NotificationDetails(android: androidDetails);

            await flutterLocalNotificationsPlugin.show(
              0,
              'التنبيه',
              'حان الآن موعد صلاة $prayerName',
              notifDetails,
            );

            // 🎵 Play Athan
            final player = AudioPlayer();
            await player.setAsset('assets/voice/azan.mp3');
            await player.play();
          }
        }
      }
    }
    return Future.value(true);
  });
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(392.72727272727275, 800.7272727272727),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context)=>AppCubit()..requestOverlay(),
          ),
          BlocProvider(create: (context)=>TextQuranCubit()..loadJsonAsset(), ),
          BlocProvider(create: (context)=>AzkarCubit(), ),
          BlocProvider(create: (context)=>PrayerTimesCubit()..fetchPrayerTimes(), ),
          BlocProvider(create: (context)=>AudioQuranCubit(), ),
        ],
        child: MaterialApp(
          title: 'Moshaf',
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
            )
          ),
          debugShowCheckedModeBanner: false,
          home: AppLayout(),
        ),
      ),
    );
  }
}

