import 'dart:async';
import 'dart:io';
import 'dart:math';
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

  /// returns "hh:mm a" for the upcoming prayer (English numerals + AM/PM)
  String get upcomingPrayerTime {
    final dt = prayerTimes[upComingPrayer];
    if (dt == null) return "";
    return DateFormat('hh:mm a').format(dt);
  }

  /// formatted sunrise (الشروق)
  String get sunriseTime => _formatPrayerTime('الشروق');

  /// formatted sunset (المغرب)
  String get sunsetTime => _formatPrayerTime('المغرب');

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

  // --- Helpers ---

  String _formatPrayerTime(String key) {
    final dt = prayerTimes[key];
    if (dt == null) return "";
    return DateFormat('hh:mm a').format(dt);
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
    return arabicLocationNames[name] ?? name;
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

        print(prayerTimes);
        // dates
        _setDates();

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
      _setDates();

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
    sorted.removeAt(1);
    MapEntry<String, DateTime> nextPrayerEntry;
    try {
      nextPrayerEntry = sorted.firstWhere((p) => p.value.isAfter(now));
    } catch (_) {
      // all today's prayers passed — pick first and move it to tomorrow
      final first = sorted.first;
      nextPrayerEntry = MapEntry(first.key, first.value.add(const Duration(days: 1)));
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

    final player = AudioServices().player;

    // Only play when countdown reaches 0
    if (diff.inSeconds == 0) {
      try {
        await player.setAudioSource(
          AudioSource.asset(
            'assets/voice/azan.mp3',
            tag: MediaItem(
              id: 'azan',
              title: 'أذان الصلاة',
              artist: 'تنبيه الصلاة',
            ),
          ),
        );
        await player.play();
      } catch (e) {
        print('Error playing adhan in app: $e');
      }
    }

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
    return _arabicHijriMonths[hijri.hMonth];
  }

  String getDayName(){
    dayName = DateFormat('EEEE', 'ar').format(DateTime.now());
    return dayName;
  }

  void _setDates() {
    dayName = DateFormat('EEEE', 'ar').format(DateTime.now());
    date = DateFormat.yMMMMd('ar').format(DateTime.now());

    final hijri = HijriCalendar.now();
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

      final androidDetails = AndroidNotificationDetails(
        'prayer_channel',
        'Prayer Times',
        channelDescription: 'Prayer time notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('azan'),
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

        scheduledCount++;
        print("✅ Scheduled notification for $prayerName at ${DateFormat('hh:mm a').format(time)}");
      } catch (e) {
        print("❌ Error scheduling $prayerName: $e");
      }
    }

    print("📅 Scheduled $scheduledCount prayer notifications");

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
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> scheduleDoaaNotifications() async {
    // 🔹 Cancel any existing scheduled notifications first
    await flutterLocalNotificationsPlugin.cancel(0);
    final List skippedNotification = await CacheHelper.getData(key: "mutedNotifications")??[];
    if(skippedNotification.contains("ادعية")) return;
    print("📅 Scheduling Doaa notifications...");
    final scheduledDate = _nextInstanceOfTime(15, 0);

    final androidDetails = AndroidNotificationDetails(
      'doaa_channel',
      'Doaa Notifications',
      channelDescription: 'Daily doaa (zekr) at 3:00 PM',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    final notifDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      getRandomDoaa()['category'],
      getRandomDoaa()['zekr'],
      scheduledDate,
      notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    print("✅ Scheduled daily Doaa at ${DateFormat('hh:mm a').format(scheduledDate)} (local)");
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
        final hijri = HijriCalendar.fromDate(targetDay);
        final monthName = _arabicHijriMonths[hijri.hMonth];
        hijriDate =
        "${_toArabicDigits(hijri.hDay.toString())} $monthName ${_toArabicDigits(hijri.hYear.toString())}";


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

}
