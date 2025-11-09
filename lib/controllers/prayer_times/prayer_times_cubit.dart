import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moshaf/controllers/prayer_times/prayer_times_states.dart';
import 'package:quran/quran.dart' as quran;
import 'package:timezone/timezone.dart' as tz;

import '../../components/audio_service.dart';
import '../../components/cache_helper.dart';
import '../../constants/app_const.dart';
import '../../constants/azkar.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesStates> {
  PrayerTimesCubit() : super(PrayerTimesInitialStates());
  static PrayerTimesCubit get(context) => BlocProvider.of(context);

  final Dio _dio = Dio();
  Timer? _remainingTimeTimer;

  // Internal state
  final Map<String, DateTime> prayerTimes = {}; // keys: Arabic names like "الفجر"
  String upComingPrayer = ""; // name of next prayer (Arabic), kept public by your UI
  String remainingTime = ""; // Arabic string like "٠٢ ساعه ١٠ دقيقه"
  String hijriDate = "";
  String dayName = "";
  String date = "";

  // --- Public convenience getters used by the UI ---

  /// UI: check whether we have data to render
  bool get hasData => prayerTimes.isNotEmpty && upComingPrayer.isNotEmpty;


  List<Map<String, String>> get prayerTimesList {
    final order = [
      "الفجر",
      "الشروق",
      "الظهر",
      "العصر",
      "المغرب",
      "العشاء",
      "منتصف الليل",
      "الثلث الاخير"
    ];

    // Define iqama offsets in minutes (can be customized)
    final Map<String, int> iqamaOffsets = {
      "الفجر": 25,
      "الشروق" : 20,
      "الظهر": 20,
      "العصر": 20,
      "المغرب": 5,
      "العشاء": 20,
    };

    final List<Map<String, String>> list = [];
    if(prayerTimesForDay.isEmpty){
      for (final name in order) {
        final dt = prayerTimes[name];
        if (dt != null) {
          final iqamaOffset = iqamaOffsets[name] ?? 0;
          final iqamaTime = dt.add(Duration(minutes: iqamaOffset));

          list.add({
            'name': name,
            'time': DateFormat('hh:mm a').format(dt),
            'iqama': iqamaOffset == 0 ? '-' : DateFormat('hh:mm a').format(iqamaTime),
          });
        }
      }

    }
    else{
      for (final name in order) {
        final dt = prayerTimesForDay[name];
        if (dt != null) {
          final iqamaOffset = iqamaOffsets[name] ?? 0;
          final iqamaTime = dt.add(Duration(minutes: iqamaOffset));

          list.add({
            'name': name,
            'time': DateFormat('hh:mm a').format(dt),
            'iqama': iqamaOffset == 0 ? '-' : DateFormat('hh:mm a').format(iqamaTime),
          });
        }
      }

    }

    return list;
  }


  /// Convert English time/AMPM/digits into Arabic script for display.
  /// Example input: "04:43 AM" -> returns Arabic digits + صباحاً/مساءً
  String convertToArabic(String input) {
    if (input.isEmpty) return input;
    input = input.replaceAll(RegExp(r'\bAM\b', caseSensitive: false), "ص");
    input = input.replaceAll(RegExp(r'\bPM\b', caseSensitive: false), 'م');

    const map = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };

    map.forEach((k, v) => input = input.replaceAll(k, v));
    return input;
  }

  // --- Location helper (unchanged behaviour) ---
  String city = "";
  String country = "";

  String translateToArabic(String name) {
    return AppConstants.arabicLocationNames[name] ?? name;
  }

  Future<Position> _determinePosition() async {
    try {
      // Try cached coordinates first
      final cachedLat = await CacheHelper.getData(key: 'cached_latitude');
      final cachedLon = await CacheHelper.getData(key: 'cached_longitude');

      Position position;

      if (cachedLat != null && cachedLon != null) {
        position = Position(
          latitude: cachedLat,
          longitude: cachedLon,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        debugPrint("✅ Using cached location: ($cachedLat, $cachedLon)");
      } else
      {
        // Request permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception("Location permission denied.");
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw Exception("Location permissions are permanently denied.");
        }

        // Get current position
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Cache it for future use
        await CacheHelper.saveData(key: 'cached_latitude', value: position.latitude);
        await CacheHelper.saveData(key: 'cached_longitude', value: position.longitude);

        debugPrint("📍 Got live location: (${position.latitude}, ${position.longitude})");
      }

      // 🌍 Get city and country using reverse geocoding
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality ?? place.subAdministrativeArea ?? "";
          country = place.country ?? "";
          debugPrint("🏙️ City: $city — 🇺🇳 Country: $country");
        }
      } catch (geoError) {
        debugPrint("⚠️ Error during reverse geocoding: $geoError");
      }

      return position;
    } catch (e, s)
    {
      debugPrint("❌ Error determining position: $e\n$s");

      // Fallback to cache
      final cachedLat = await CacheHelper.getData(key: 'cached_latitude');
      final cachedLon = await CacheHelper.getData(key: 'cached_longitude');
      if (cachedLat != null && cachedLon != null) {
        final fallback = Position(
          latitude: cachedLat,
          longitude: cachedLon,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        // Try reverse geocoding fallback
        try {
          final placemarks = await placemarkFromCoordinates(cachedLat, cachedLon);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            city = place.locality ?? place.subAdministrativeArea ?? "";
            country = place.country ?? "";
          }
        } catch (_) {}

        return fallback;
      }

      // Final fallback if no location at all
      city = "";
      country = "";
      return Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }
  }


  // --- API and parsing ---
  DateTime _parseApiTimeToToday(String hhmm24) {
    // Aladhan returns "HH:mm" — parse and attach today's date
    final parsed = DateFormat("HH:mm").parse(hhmm24);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, parsed.hour, parsed.minute);
  }

  /// Fetch prayer times and populate internal state
  Future<void> fetchPrayerTimes() async {
    emit(GetPrayerTimesLoadingState());
    try {
      final pos = await _determinePosition();
      final url =
          'http://api.aladhan.com/v1/timings?latitude=${pos.latitude}&longitude=${pos.longitude}';
      final res = await _dio.get(url);

      if (res.statusCode == 200) {

        final data = Map<String, dynamic>.from(res.data['data']['timings']);
        // print(res.data['data']);
        // store as DateTime objects keyed by Arabic names
        prayerTimes.clear();
        prayerTimes['الفجر'] = _parseApiTimeToToday(data['Fajr'] ?? '00:00');
        prayerTimes['الشروق'] = _parseApiTimeToToday(data['Sunrise'] ?? '00:00');
        prayerTimes['الظهر'] = _parseApiTimeToToday(data['Dhuhr'] ?? '00:00');
        prayerTimes['العصر'] = _parseApiTimeToToday(data['Asr'] ?? '00:00');
        prayerTimes['المغرب'] = _parseApiTimeToToday(data['Maghrib'] ?? '00:00');
        prayerTimes['العشاء'] = _parseApiTimeToToday(data['Isha'] ?? '00:00');
        prayerTimes['منتصف الليل'] = _parseApiTimeToToday(data['Midnight'] ?? '00:00');
        prayerTimes['الثلث الاخير'] = _parseApiTimeToToday(data['Lastthird'] ?? '00:00');

        // prayerTimes['الفجر'] = DateTime.now().add(Duration(seconds: 5));
        // prayerTimes['الشروق'] = _parseApiTimeToToday(data['Sunrise'] ?? '00:00');
        // prayerTimes['الظهر'] = DateTime.now().add(Duration(seconds: 10));
        // prayerTimes['العصر'] = DateTime.now().add(Duration(seconds: 15));
        // prayerTimes['المغرب'] = DateTime.now().add(Duration(seconds: 20));
        // prayerTimes['العشاء'] = DateTime.now().add(Duration(seconds: 25));
        // prayerTimes['منتصف الليل'] = _parseApiTimeToToday(data['Midnight'] ?? '00:00');
        // prayerTimes['الثلث الاخير'] = _parseApiTimeToToday(data['Lastthird'] ?? '00:00');

        // print(prayerTimes);
        // dates
        _setDates(datetime: DateTime.now());

        CacheHelper.saveData(key: 'last_prayer_update',value:  DateTime.now().toIso8601String());


        // find upcoming prayer & start timer
        _updateUpcomingPrayer();
        _startRemainingTimeUpdater();
        CacheHelper.saveMap(
          key: 'cached_prayer_times',
          myMap: prayerTimes.map((k, v) => MapEntry(k, v.toIso8601String())),
        );

        CacheHelper.saveMap(
          key: 'cached_prayer_upcoming',
          myMap: {'upComingPrayer': upComingPrayer},
        );

        await scheduleAllPrayerNotifications();
        if(Platform.isIOS){
          await updateWidgetsData();
          // 🎯 Start Live Activity for the next prayer
          final nextTime = prayerTimes[upComingPrayer];
          if (nextTime != null) {
            await startPrayerActivity(prayer: upComingPrayer, prayerTime: nextTime);
            await updatePrayerCountdown();
          }
        }
        else{
          final nextTime = prayerTimes[upComingPrayer];
          updatePrayerWidget(
            upcomingPrayer: upComingPrayer,
            upcomingTime: nextTime!,
            allPrayers: prayerTimes
          );
          await scheduleNextPrayerWidgetUpdate(prayerTimes);
        }
        // final now = DateTime.now();
        // await _scheduleAllPrayerNotifications({
        //   'Fajr': now.add(const Duration(minutes: 1)),
        //   'Dhuhr': now.add(const Duration(minutes: 2)),
        //   'Asr': now.add(const Duration(minutes: 3)),
        //   'Maghrib': now.add(const Duration(minutes: 4)),
        //   'Isha': now.add(const Duration(minutes: 5)),
        // });

        emit(GetPrayerTimesSuccessState());
      } else {
        loadCachedPrayerTimes();
        emit(GetPrayerTimesErrorState());
      }
    } catch (e) {
      print(e);
      loadCachedPrayerTimes();
      emit(GetPrayerTimesErrorState());
    }
  }

  Future<bool> loadCachedPrayerTimes() async {
    final cachedTimes = await CacheHelper.getMap(key: 'cached_prayer_times');
    final cachedUpcoming = await CacheHelper.getMap(key: 'cached_prayer_upcoming');

    if (cachedTimes != null && cachedUpcoming != null) {
      prayerTimes.clear();
      cachedTimes.forEach((k, v) {
        prayerTimes[k] = DateTime.parse(v);
      });

      upComingPrayer = cachedUpcoming['upComingPrayer'] ?? '';
      _setDates(datetime: DateTime.now());

      // find upcoming prayer & start timer
      _updateUpcomingPrayer();
      _startRemainingTimeUpdater();
      emit(GetPrayerTimesSuccessState());
      return true;
    }
    return false;
  }


  // --- Upcoming prayer logic (fixed no copyWith) ---
  void _updateUpcomingPrayer() {
    final now = DateTime.now();
    final sorted = prayerTimes.entries.toList().sublist(0,6)
      ..sort((a, b) => a.value.compareTo(b.value));
    sorted.remove(sorted.firstWhere((element) => element.key == "الشروق"));
    MapEntry<String, DateTime> nextPrayerEntry;
    try {
      nextPrayerEntry = sorted.firstWhere((p) => p.value.isAfter(now));
    } catch (_) {
      // all today's prayers passed — pick first and move it to tomorrow
      final first = sorted.first;
      nextPrayerEntry = MapEntry('الفجر', first.value.add(const Duration(days: 1)));
      prayerTimes['الفجر'] = nextPrayerEntry.value;
    }
    upComingPrayer = nextPrayerEntry.key;
    emit(GetNextPrayerSuccessState());
  }

  // --- Remaining time updater ---
  void _startRemainingTimeUpdater() {
    _remainingTimeTimer?.cancel();
    // calculate immediately
    _calculateRemainingTime();
    // keep ticking each second for responsive UI
    _remainingTimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemainingTime();
    });
  }

  void _calculateRemainingTime() async {
    final now = DateTime.now();
    final next = prayerTimes[upComingPrayer];
    if (next == null) return;
    if (next.isBefore(now)) {
      // 🔁 Update to next prayer time
      _updateUpcomingPrayer();
      return;
    }
    final target = next.isBefore(now) ? next.add(const Duration(days: 1)) : next;
    final diff = target.difference(now);

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    // Format to HH : MM : SS with Arabic digits
    remainingTime =
    "${_toArabicDigits(seconds.toString().padLeft(2, '0'))} : "
        "${_toArabicDigits(minutes.toString().padLeft(2, '0'))} : "
            "${_toArabicDigits(hours.toString().padLeft(2, '0'))}";



    emit(UpdateRemainingTime());
  }

  String _toArabicDigits(String s) {
    const map = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    map.forEach((k, v) => s = s.replaceAll(k, v));
    return s;
  }
  static const _arabicHijriMonths = [
    "مُحَرَّم",
    "صَفَر",
    "رَبيعُ الأوَّل",
    "رَبيعُ الآخِر",
    "جُمادى الأُولَى",
    "جُمادى الآخِرَة",
    "رَجَب",
    "شَعْبان",
    "رَمَضان",
    "شَوَّال",
    "ذُو القَعْدَةِ",
    "ذُو الحِجَّة",
  ];
  // --- Dates ---
  String getHijriMonth(){
    final hijri = HijriCalendar.now();
    return _arabicHijriMonths[hijri.hMonth-1];
  }

  String getDayName(){

    return DateFormat('EEEE', 'ar').format(DateTime.now());
  }

  void _setDates({
    required DateTime datetime
}) {
    dayName = DateFormat('EEEE', 'ar').format(datetime);
    date = DateFormat.yMMMMd('ar').format(datetime);

    final hijri = HijriCalendar.fromDate(datetime);
    final monthName = _arabicHijriMonths[hijri.hMonth - 1];
    hijriDate = "${_toArabicDigits(hijri.hDay.toString())} $monthName ${_toArabicDigits(hijri.hYear.toString())}";
    // if you want Arabic digits inside hijriDate, wrap numbers using _toArabicDigits
  }

  @override
  Future<void> close() {
    _remainingTimeTimer?.cancel();
    return super.close();
  }

  Map<String, String>? get pastEvent {
    if (prayerTimes.isEmpty) return null;
    final now = DateTime.now();
    final sorted = prayerTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Find the latest prayer time before now
    MapEntry<String, DateTime>? last;
    for (final entry in sorted) {
      if (entry.value.isBefore(now)) {
        last = entry;
      }
    }

    // If nothing before now, wrap to yesterday’s last prayer
    last ??= sorted.last;

    return {
      'name': last.key,
      'time': DateFormat('hh:mm a').format(last.value),
    };
  }
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  // Future<void> scheduleNextPrayer(Map<String, String> prayerTimes) async {
  //   final now = DateTime.now();
  //
  //   // Sort prayers chronologically
  //   final sorted = prayerTimes.entries
  //       .map((e) => DateTime.parse(e.value))
  //       .where((t) => t.isAfter(now))
  //       .toList()
  //     ..sort();
  //
  //   if (sorted.isEmpty) return; // no more prayers today
  //
  //   final nextPrayer = sorted.first;
  //
  //   // Schedule with flutter_local_notifications
  //   final androidDetails = AndroidNotificationDetails(
  //     'athan_channel',
  //     'Athan Notifications',
  //     sound: RawResourceAndroidNotificationSound('azan'),
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     playSound: true,
  //   );
  //   final details = NotificationDetails(android: androidDetails);
  //
  //   await flutterLocalNotificationsPlugin.zonedSchedule(
  //     0,
  //     'Prayer Time',
  //     'It\'s time for prayer',
  //     tz.TZDateTime.from(nextPrayer, tz.local),
  //     details,
  //     uiLocalNotificationDateInterpretation:
  //     UILocalNotificationDateInterpretation.absoluteTime,
  //       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
  //   );
  // }

  Future<void> scheduleAllPrayerNotifications() async {
    final List skippedNotification = await CacheHelper.getData(key: "mutedNotifications")??[];
    print("📅 Scheduling prayer notifications...");

    // 🔹 Cancel any existing scheduled notifications first
    await flutterLocalNotificationsPlugin.cancelAll();
    print("🗑️ Cleared all previously scheduled notifications.");

    final now = DateTime.now();
    int scheduledCount = 0;

    for (final entry in prayerTimes.entries) {
      final prayerName = entry.key;
      final time = entry.value;
      if(prayerName == "الشروق"||prayerName == "منتصف الليل"||prayerName == "الثلث الاخير") continue;
      // Skip prayers that already passed today
      if (time.isBefore(now)||skippedNotification.contains("صلاة $prayerName")) {
        print("⏭️ Skipping $prayerName - already passed");
        continue;
      }
      if(Platform.isAndroid){
        final azanOption = await CacheHelper.getData(key: "azanSound")??"اذان الحرم المكي";
        String audioFileName = "";

        switch(azanOption){
          case "اذان الحرم المكي":
            audioFileName = "azan";
            break;
          case "عبد الباسط عبد الصمد":
            audioFileName = "abdullbaset";
            break;
          case "ناصر القطامي":
            audioFileName = "naser_alkatamy";
            break;
          case "صالح الجعفراوي":
            audioFileName = "saleh_algafrawy";
            break;
          default:
            audioFileName = "azan";
            break;
        }

        final androidDetails = AndroidNotificationDetails(
          'prayer_channel_$audioFileName',
          'Prayer Times ($audioFileName)',
          channelDescription: 'Prayer time notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: false,

          // sound: RawResourceAndroidNotificationSound(audioFileName),
        );

        final notifDetails = NotificationDetails(android: androidDetails);

        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            time.hashCode,
            'وقت الصلاة',
            'حان الآن موعد صلاة $prayerName',
            tz.TZDateTime.from(time, tz.local),
            notifDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          await AndroidAlarmManager.oneShotAt(
            time,
            time.hashCode,
            playAzanCallback,
            params: {'file': audioFileName},
            exact: true,
            wakeup: true,
            allowWhileIdle: true,
          );

          scheduledCount++;
          print("✅ Scheduled notification for $prayerName at ${DateFormat('hh:mm a').format(time)}");
        } catch (e) {
          print("❌ Error scheduling $prayerName: $e");
        }

      }
      else{
       try{
         final iosDetails = DarwinNotificationDetails(
           presentAlert: true,  // show alert banner
           presentBadge: true,  // update app icon badge
           presentSound: true,  // play notification sound
           interruptionLevel: InterruptionLevel.timeSensitive,
         );
         final notifDetails = NotificationDetails(iOS: iosDetails);

         await flutterLocalNotificationsPlugin.zonedSchedule(
           time.hashCode,
           'وقت الصلاة',
           'حان الآن موعد صلاة $prayerName',
           tz.TZDateTime.from(time, tz.local),
           notifDetails,
           androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
           matchDateTimeComponents: DateTimeComponents.time,
         );
         scheduledCount++;
         print("✅ Scheduled notification for $prayerName at ${DateFormat('hh:mm a').format(time)}");
       }catch (e) {
         print("❌ Error scheduling $prayerName: $e");
       }
      }
    }
    print("📅 Scheduled $scheduledCount prayer notifications");
    await scheduleDoaaNotifications();
    // // If no prayers left today, schedule tomorrow's prayers
    // if (scheduledCount == 0) {
    //   print("⚠️ No prayers left today, will fetch tomorrow's prayers");
    //   await _scheduleTomorrowsPrayers();
    // }
  }

  Future<bool> shouldFetchNewTimes() async {
    final lastUpdate =await CacheHelper.getData(key: 'last_prayer_update');

    if (lastUpdate == null) {
      return true; // First time, need to fetch
    }

    final lastDate = DateTime.parse(lastUpdate);
    final now = DateTime.now();

    // Check if it's a new day
    if (lastDate.day != now.day ||
        lastDate.month != now.month ||
        lastDate.year != now.year) {
      return true; // New day, fetch new times
    }

    return true; // Same day, use cache
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 18, now.minute+1);
    // if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
    //   scheduled = scheduled.add(const Duration(days: 1));
    // }
    return scheduled;
  }

  Future<void> scheduleDoaaNotifications() async {
    // 🔹 Cancel any existing scheduled notifications first
    await flutterLocalNotificationsPlugin.cancel(0);
    final List skippedNotification = await CacheHelper.getData(key: "mutedNotifications")??[];
    if(skippedNotification.contains("ادعية")) return;
    print("📅 Scheduling Doaa notifications...");
    final now = DateTime.now();
    final scheduledDate = DateTime(now.year, now.month, now.day, 15, 0);
    if(scheduledDate.isBefore(now)){
      scheduledDate.add(const Duration(days: 1));
    }

    final String category = getRandomDoaa()['category'];
    final String zekr = getRandomDoaa()['zekr'];
    print(zekr);
    print(category);

    if(Platform.isAndroid){
      final androidDetails = AndroidNotificationDetails(
        'doaa_channel',
        'Doaa Notifications',
        channelDescription: 'Daily doaa (zekr) at 3:00 PM',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );



      final notifDetails = NotificationDetails(android: androidDetails);
      // await flutterLocalNotificationsPlugin.show(0, category, zekr, notifDetails);
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        category,
        zekr,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print("✅ Scheduled daily Doaa at ${DateFormat('hh:mm a').format(scheduledDate)} (local)");
    }
    else if(Platform.isIOS){
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,  // show alert banner
        presentBadge: true,  // update app icon badge
        presentSound: true,  // play notification sound
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
      final notifDetails = NotificationDetails(iOS: iosDetails);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        category,
        zekr,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
    final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    // Check if our notification ID (0) exists
    final exists = pending.any((notif) => notif.id == 0);

    if (exists) {
      print("✅ Doaa notification is scheduled successfully!");
    } else {
      print("⚠️ Doaa notification was NOT scheduled.");
    }
  }

  Future<void> pushInstantNotification()async{
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,  // show alert banner
      presentBadge: true,  // update app icon badge
      presentSound: true,  // play notification sound
      // sound: 'default.wav', // optional custom sound from ios/Runner directory
      interruptionLevel: InterruptionLevel.timeSensitive, // optional: iOS 15+ style
    );
    final notifDetails = NotificationDetails(iOS: iosDetails);

    await flutterLocalNotificationsPlugin.show(7000, "category", "zekr", notifDetails);
    print("done");
  }

  Map getRandomDoaa(){
    List doaa = [
      AzkarConstants.adeyaQuranya,
      AzkarConstants.adeyahNabaweyah,
      AzkarConstants.adeyatAlanbiya,
    ];

    int randomIndex = Random().nextInt(doaa.length);
    int randomDoaa = Random().nextInt(doaa[randomIndex]['azkar'].length);

    return {"category": doaa[randomIndex]['category'], "zekr": doaa[randomIndex]['azkar'][randomDoaa]['zekr']};
  }

  Future<void> fireQuranRemindedNotifications() async {
    // final String lastReadDate = await CacheHelper.getData(key: 'lastRead');

    // 🔹 Cancel any existing scheduled notifications first
    await flutterLocalNotificationsPlugin.cancel(1);

    final List? skippedNotification = await CacheHelper.getData(key: "mutedNotifications");
    final int? lastRead = await CacheHelper.getData(key: "sora");

    // 🔹 If muted or no last-read surah → don't send
    if (skippedNotification?.contains("تذكير بالمصحف") ?? false || lastRead == null) return;

    print("🚀 Sending immediate Quran reminder notification...");

    String sorahName = quran.getSurahNameArabic(lastRead!);

    // 🔹 Android notification configuration
    const androidDetails = AndroidNotificationDetails(
      'quran_channel',
      'Quran Notifications',
      channelDescription: 'Quran reading reminder',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    // 🔹 Send immediately
    await flutterLocalNotificationsPlugin.show(
      1, // notification ID
      "لا تكن هاجراً للقرآن", // title
      "تذكير بقراءة سورة $sorahName", // body
      notifDetails,
    );

    print("✅ Immediate Quran reminder notification sent successfully!");
  }


  int prayerDayOffset = 0; // 0 = today, +1 = tomorrow, -1 = yesterday
  final Map<String, DateTime> prayerTimesForDay = {}; // Current day's timings

  Future<void> fetchPrayerTimesForOffset() async {
    emit(GetPrayerTimesLoadingState());

    try {
      // 1️⃣ Get current location
      final pos = await _determinePosition();

      // 2️⃣ Compute target day based on offset
      final targetDay = DateTime.now().add(Duration(days: prayerDayOffset));
      print("📅 Fetching prayers for offset $prayerDayOffset → $targetDay");

      final timestamp = (targetDay.millisecondsSinceEpoch ~/ 1000);

      // 3️⃣ Build API URL
      final url =
          'http://api.aladhan.com/v1/timings/$timestamp?latitude=${pos.latitude}&longitude=${pos.longitude}&method=5';

      final res = await _dio.get(url);

      if (res.statusCode == 200) {
        // 4️⃣ Parse data
        final data = Map<String, dynamic>.from(res.data['data']['timings']);
        prayerTimesForDay.clear();

        prayerTimesForDay['الفجر'] = _parseApiTimeToDay(data['Fajr'], targetDay);
        prayerTimesForDay['الشروق'] = _parseApiTimeToDay(data['Sunrise'], targetDay);
        prayerTimesForDay['الظهر'] = _parseApiTimeToDay(data['Dhuhr'], targetDay);
        prayerTimesForDay['العصر'] = _parseApiTimeToDay(data['Asr'], targetDay);
        prayerTimesForDay['المغرب'] = _parseApiTimeToDay(data['Maghrib'], targetDay);
        prayerTimesForDay['العشاء'] = _parseApiTimeToDay(data['Isha'], targetDay);
        prayerTimesForDay['منتصف الليل'] = _parseApiTimeToDay(data['Midnight'] ?? '00:00',targetDay);
        prayerTimesForDay['الثلث الاخير'] = _parseApiTimeToDay(data['Lastthird'] ?? '00:00',targetDay);

        // 5️⃣ Update Gregorian labels
        dayName = DateFormat('EEEE', 'ar').format(targetDay);
        date = DateFormat.yMMMMd('ar').format(targetDay);

        // 6️⃣ Convert Gregorian → Hijri
        // final hijri = HijriCalendar.fromDate(targetDay);
        // final monthName = _arabicHijriMonths[hijri.hMonth];
        // hijriDate =
        // "${_toArabicDigits(hijri.hDay.toString())} $monthName ${_toArabicDigits(hijri.hYear.toString())}";
        _setDates(datetime: targetDay);


        emit(GetPrayerTimesSuccessState());
      } else {
        emit(GetPrayerTimesErrorState());
      }
    } catch (e) {
      print("❌ fetchPrayerTimesForOffset error: $e");
      emit(GetPrayerTimesErrorState());
    }
  }

  void nextPrayerDay() {
    prayerDayOffset++;
    fetchPrayerTimesForOffset();
  }

  /// Move backward one day
  void previousPrayerDay() {
    prayerDayOffset--;
    fetchPrayerTimesForOffset();
  }

  /// Reset to today
  void resetToToday() {
    prayerDayOffset = 0;
    fetchPrayerTimesForOffset();
  }




  DateTime _parseApiTimeToDay(String time, DateTime day) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

///ios Home widget
  Future<void> updateWidgetsData() async {
    if (prayerTimes.isEmpty) return;

    final upcoming = upComingPrayer;
    final upcomingTime = prayerTimes[upComingPrayer];

    // ✅ Use Arabic locale and 12-hour clock
    final arabicFormatter = DateFormat('hh:mm a', 'ar');
    final upcomingTimeStr = arabicFormatter.format(upcomingTime!);

    await HomeWidget.saveWidgetData<String>('prayer_name', upcoming);
    await HomeWidget.saveWidgetData<String>('prayer_time', upcomingTimeStr);

    final all = prayerTimes.map(
          (k, v) => MapEntry(k, arabicFormatter.format(v)),
    );
    await HomeWidget.saveWidgetData<Map<String, String>>('all_prayers', all);

    await HomeWidget.updateWidget(
      name: 'PrayerWidgetExtension',
      iOSName: 'PrayerWidgetExtension',
    );
  }

  final _channel = MethodChannel('mostakeem/live_activity');

  Future<void> startPrayerActivity({
    required String prayer,
    required DateTime prayerTime,
  }) async {
    final remaining = prayerTime.difference(DateTime.now()).inSeconds.toDouble();

    await _channel.invokeMethod('startActivity', {
      'upcomingPrayer': prayer,
      'remaining': remaining,
      'upcomingTime': DateFormat('hh:mm a', 'ar').format(prayerTime),
    });
  }

  Future<void> updatePrayerCountdown() async {
    Timer.periodic(const Duration(seconds: 30), (_) async {
      final nextPrayerTime = prayerTimes[upComingPrayer];
      if (nextPrayerTime == null) return;

      final diff = nextPrayerTime.difference(DateTime.now()).inSeconds.toDouble();

      if (diff <= 0) {
        await _channel.invokeMethod('endActivity');
        // 🕌 Start next prayer automatically
        _updateUpcomingPrayer();
        final newTime = prayerTimes[upComingPrayer];
        if (newTime != null) {
          await startPrayerActivity(prayer: upComingPrayer, prayerTime: newTime);
        }
      } else {
        await _channel.invokeMethod('updateActivity', {'remaining': diff});
      }
    });
  }



  /// android Home Widget

  Future<void> updatePrayerWidget({
    required String upcomingPrayer,
    required DateTime upcomingTime,
    required Map<String, DateTime> allPrayers,
  }) async
  {
    String formatArabicTime(DateTime time) {
      final formatted = DateFormat('hh:mm a', 'ar').format(time);
      // Replace AM/PM with Arabic equivalents
      final arabicTime = formatted
          .replaceAll('AM', 'ص')
          .replaceAll('PM', 'م');
      // Convert Western digits to Arabic numerals
      const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      var result = arabicTime;
      for (int i = 0; i < western.length; i++) {
        result = result.replaceAll(western[i], arabic[i]);
      }
      return result;
    }

    // ✅ Format upcoming prayer time in Arabic 12-hour style
    final formattedUpcoming = formatArabicTime(upcomingTime);

    // Save upcoming prayer
    await HomeWidget.saveWidgetData<String>('prayer_name', upcomingPrayer);
    await HomeWidget.saveWidgetData<String>('prayer_time', formattedUpcoming);

    // ✅ Save all prayer times individually (formatted)
    for (final entry in allPrayers.entries) {
      final formattedTime = formatArabicTime(entry.value);
      await HomeWidget.saveWidgetData<String>(entry.key, formattedTime);
    }

    // ✅ Update both widgets
    await HomeWidget.updateWidget(name: 'HomeWidgetSmallProvider');
    await HomeWidget.updateWidget(name: 'HomeWidgetLargeProvider');
  }

  Future<void> scheduleNextPrayerWidgetUpdate(Map<String, DateTime> allPrayers) async {
    final now = DateTime.now();

    // 🔹 Filter out unwanted prayers
    final upcoming = allPrayers.entries
        .where((e) =>
    e.value.isAfter(now) &&
        e.key != 'منتصف الليل' &&
        e.key != 'الثلث الاخير')
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    if (upcoming.isEmpty) {
      print("⚠️ No upcoming prayers today, scheduling for tomorrow");
      // Schedule for first prayer tomorrow
      final tomorrow = now.add(Duration(days: 1));
      final firstPrayerTomorrow = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        allPrayers['الفجر']?.hour ?? 5,
        allPrayers['الفجر']?.minute ?? 0,
      );

      await AndroidAlarmManager.oneShotAt(
        firstPrayerTomorrow,
        1001,
        updatePrayerWidgetCallback,
        exact: true,
        wakeup: true,
      );
      debugPrint('⏰ Scheduled widget update for tomorrow at ${firstPrayerTomorrow}');
      return;
    }

    final nextPrayer = upcoming.first;

    // 🔹 Save next prayer info for background callback
    await CacheHelper.saveData(
      key: 'next_prayer_name',
      value: nextPrayer.key,
    );
    await CacheHelper.saveData(
      key: 'next_prayer_time',
      value: nextPrayer.value.toIso8601String(),
    );

    // 🔹 Schedule widget update at the next prayer time
    await AndroidAlarmManager.oneShotAt(
      nextPrayer.value,
      1001, // unique alarm ID
      updatePrayerWidgetCallback,
      exact: true,
      wakeup: true,
    );

    debugPrint('⏰ Scheduled widget auto-update for ${nextPrayer.key} at ${nextPrayer.value}');
  }




}


@pragma('vm:entry-point')
void updatePrayerWidgetCallback() async {
  print("🔔 Widget update callback triggered!");
  await initializeDateFormatting('ar');
  try {
    // 1️⃣ Load cached prayer data
    final cachedTimes = await CacheHelper.getMap(key: 'cached_prayer_times');
    final cachedUpcoming = await CacheHelper.getMap(key: 'cached_prayer_upcoming');

    if (cachedTimes == null || cachedUpcoming == null) {
      print("❌ No cached prayer data found");
      return;
    }

    // 2️⃣ Parse prayer times
    final allPrayers = cachedTimes.map((k, v) {
      try {
        return MapEntry(k, DateTime.parse(v));
      } catch (e) {
        print("❌ Error parsing prayer time $k: $e");
        return MapEntry(k, DateTime.now());
      }
    });

    final now = DateTime.now();

    // 3️⃣ Find next upcoming prayer
    final upcoming = allPrayers.entries
        .where((e) =>
    e.value.isAfter(now) &&
        e.key != 'منتصف الليل' &&
        e.key != 'الثلث الاخير')
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    String upcomingPrayer;
    DateTime? upcomingTime;

    if (upcoming.isNotEmpty) {
      upcomingPrayer = upcoming.first.key;
      upcomingTime = upcoming.first.value;
      print("✅ Next prayer: $upcomingPrayer at $upcomingTime");
    } else {
      print("⚠️ No more prayers today, using cached upcoming");
      upcomingPrayer = cachedUpcoming['upComingPrayer'] ?? 'الفجر';
      upcomingTime = allPrayers[upcomingPrayer];
    }

    if (upcomingTime == null) {
      print("❌ Could not find upcoming prayer time");
      return;
    }

    // 4️⃣ Format time for widget
    String formatArabicTime(DateTime time) {
      final formatted = DateFormat('hh:mm a', 'ar').format(time);
      final arabicTime = formatted
          .replaceAll('AM', 'ص')
          .replaceAll('PM', 'م');

      const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      var result = arabicTime;
      for (int i = 0; i < western.length; i++) {
        result = result.replaceAll(western[i], arabic[i]);
      }
      return result;
    }

    final formattedTime = formatArabicTime(upcomingTime);

    // 5️⃣ Update widgets
    await HomeWidget.saveWidgetData<String>('prayer_name', upcomingPrayer);
    await HomeWidget.saveWidgetData<String>('prayer_time', formattedTime);

    // Also save all prayer times
    for (final entry in allPrayers.entries) {
      final formattedPrayerTime = formatArabicTime(entry.value);
      await HomeWidget.saveWidgetData<String>(entry.key, formattedPrayerTime);
    }

    await HomeWidget.updateWidget(name: 'HomeWidgetSmallProvider');
    await HomeWidget.updateWidget(name: 'HomeWidgetLargeProvider');

    print("✅ Widget updated successfully!");

    // 6️⃣ Schedule next update
    // Create a temporary cubit instance to schedule the next alarm
    final cubit = PrayerTimesCubit();
    await cubit.scheduleNextPrayerWidgetUpdate(allPrayers);

  } catch (e, s) {
    print("❌ Error in updatePrayerWidgetCallback: $e\n$s");
  }


}

@pragma('vm:entry-point')
void playAzanCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  final player = AudioServices().player;
  try {
    // You can store the selected azan sound in SharedPreferences or CacheHelper
    final azanOption = await CacheHelper.getData(key: "azanSound") ?? "azan";
    await player.setAsset('assets/audio/$azanOption.mp3');
    await player.play();
  } catch (e) {
    print('❌ Error playing Azan: $e');
  }
}

