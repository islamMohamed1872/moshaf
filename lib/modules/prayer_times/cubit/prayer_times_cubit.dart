import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moshaf/modules/prayer_times/cubit/prayer_times_states.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../components/audio_service.dart';
import '../../../components/cache_helper.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesStates> {
  PrayerTimesCubit() : super(PrayerTimesInitialStates());
  static PrayerTimesCubit get(context) => BlocProvider.of(context);

  final Dio _dio = Dio();
  Timer? _remainingTimeTimer;

  // Internal state
  final Map<String, DateTime> _prayerTimes = {}; // keys: Arabic names like "الفجر"
  String upComingPrayer = ""; // name of next prayer (Arabic), kept public by your UI
  String remainingTime = ""; // Arabic string like "٠٢ ساعه ١٠ دقيقه"
  String hijriDate = "";
  String dayName = "";
  String date = "";

  // --- Public convenience getters used by the UI ---

  /// UI: check whether we have data to render
  bool get hasData => _prayerTimes.isNotEmpty && upComingPrayer.isNotEmpty;

  /// returns "hh:mm a" for the upcoming prayer (English numerals + AM/PM)
  String get upcomingPrayerTime {
    final dt = _prayerTimes[upComingPrayer];
    if (dt == null) return "";
    return DateFormat('hh:mm a').format(dt);
  }

  /// formatted sunrise (الشروق)
  String get sunriseTime => _formatPrayerTime('الشروق');

  /// formatted sunset (المغرب)
  String get sunsetTime => _formatPrayerTime('المغرب');

  /// list used by the refactored UI to iterate rows in fixed order
  List<Map<String, String>> get prayerTimesList {
    final order = ["الفجر", "الظهر", "العصر", "المغرب", "العشاء"];
    final List<Map<String, String>> list = [];
    for (final name in order) {
      final dt = _prayerTimes[name];
      if (dt != null) {
        list.add({'name': name, 'time': DateFormat('hh:mm a').format(dt)});
      }
    }
    return list;
  }

  // --- Helpers ---

  String _formatPrayerTime(String key) {
    final dt = _prayerTimes[key];
    if (dt == null) return "";
    return DateFormat('hh:mm a').format(dt);
  }

  /// Convert English time/AMPM/digits into Arabic script for display.
  /// Example input: "04:43 AM" -> returns Arabic digits + صباحاً/مساءً
  String convertToArabic(String input) {
    if (input.isEmpty) return input;
    input = input.replaceAll(RegExp(r'\bAM\b', caseSensitive: false), "صباحًا");
    input = input.replaceAll(RegExp(r'\bPM\b', caseSensitive: false), 'مساءً');

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
  Future<Position> _determinePosition() async {
    try {
        // Try using cached location if available
        final cachedLat =await CacheHelper.getData(key: 'cached_latitude');
        final cachedLon = await CacheHelper.getData(key: 'cached_longitude');
        if (cachedLat != null && cachedLon != null) {
          return Position(
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
        }
        // throw Exception('Location unavailable and no cached data found.');
        return Position(
          latitude: 0,
          longitude: 0,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

    } catch (e) {
      // On any error, fallback to cached location
      final cachedLat =await CacheHelper.getData(key: 'cached_latitude');
      final cachedLon =await CacheHelper.getData(key: 'cached_longitude');
      if (cachedLat != null && cachedLon != null) {
        return Position(
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
      }
      rethrow;
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
        // store as DateTime objects keyed by Arabic names
        _prayerTimes.clear();
        _prayerTimes['الفجر'] = _parseApiTimeToToday(data['Fajr'] ?? '00:00');
        _prayerTimes['الشروق'] = _parseApiTimeToToday(data['Sunrise'] ?? '00:00');
        _prayerTimes['الظهر'] = _parseApiTimeToToday(data['Dhuhr'] ?? '00:00');
        _prayerTimes['العصر'] = _parseApiTimeToToday(data['Asr'] ?? '00:00');
        _prayerTimes['المغرب'] = _parseApiTimeToToday(data['Maghrib'] ?? '00:00');
        _prayerTimes['العشاء'] = _parseApiTimeToToday(data['Isha'] ?? '00:00');

        // dates
        _setDates();

        CacheHelper.saveData(key: 'last_prayer_update',value:  DateTime.now().toIso8601String());


        // find upcoming prayer & start timer
        _updateUpcomingPrayer();
        _startRemainingTimeUpdater();
        CacheHelper.saveMap(
          key: 'cached_prayer_times',
          myMap: _prayerTimes.map((k, v) => MapEntry(k, v.toIso8601String())),
        );

        CacheHelper.saveMap(
          key: 'cached_prayer_upcoming',
          myMap: {'upComingPrayer': upComingPrayer},
        );

        await _scheduleAllPrayerNotifications(_prayerTimes);
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
      _prayerTimes.clear();
      cachedTimes.forEach((k, v) {
        _prayerTimes[k] = DateTime.parse(v);
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
    final sorted = _prayerTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

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
    final next = _prayerTimes[upComingPrayer];
    if (next == null) return;

    final target = next.isBefore(now) ? next.add(const Duration(days: 1)) : next;
    final diff = target.difference(now);

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    remainingTime =
    "${_toArabicDigits(hours.toString().padLeft(2, '0'))} ساعه ${_toArabicDigits(minutes.toString().padLeft(2, '0'))} دقيقه";
    final player = AudioServices().player;

    // Only play when app is open and countdown reaches 0
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
    "محرم",
    "صفر",
    "ربيع الأول",
    "ربيع الآخر",
    "جمادى الأولى",
    "جمادى الآخرة",
    "رجب",
    "شعبان",
    "رمضان",
    "شوال",
    "ذو القعدة",
    "ذو الحجة"
  ];
  // --- Dates ---
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
    if (_prayerTimes.isEmpty) return null;
    final now = DateTime.now();
    final sorted = _prayerTimes.entries.toList()
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

  Future<void> _scheduleAllPrayerNotifications(Map<String, DateTime> times) async {
    print("📅 Scheduling prayer notifications...");

    // 🔹 Cancel any existing scheduled notifications first
    await flutterLocalNotificationsPlugin.cancelAll();
    print("🗑️ Cleared all previously scheduled notifications.");

    final now = DateTime.now();
    int scheduledCount = 0;

    for (final entry in times.entries) {
      final prayerName = entry.key;
      final time = entry.value;
      if(prayerName == "الشروق") continue;
      // Skip prayers that already passed today
      if (time.isBefore(now)) {
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

    // If no prayers left today, schedule tomorrow's prayers
    if (scheduledCount == 0) {
      print("⚠️ No prayers left today, will fetch tomorrow's prayers");
      await _scheduleTomorrowsPrayers();
    }
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

  Future<void> _scheduleTomorrowsPrayers() async {
    print("🔄 Fetching tomorrow's prayer times...");

    try {
      final pos = await _determinePosition();
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final url =
          'http://api.aladhan.com/v1/timings/${tomorrow.millisecondsSinceEpoch ~/ 1000}?latitude=${pos.latitude}&longitude=${pos.longitude}';

      final res = await _dio.get(url);

      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(res.data['data']['timings']);
        final tomorrowPrayers = <String, DateTime>{};
        tomorrowPrayers['الفجر'] = _parseApiTimeToTomorrow(data['Fajr'] ?? '00:00');
        tomorrowPrayers['الظهر'] = _parseApiTimeToTomorrow(data['Dhuhr'] ?? '00:00');
        tomorrowPrayers['العصر'] = _parseApiTimeToTomorrow(data['Asr'] ?? '00:00');
        tomorrowPrayers['المغرب'] = _parseApiTimeToTomorrow(data['Maghrib'] ?? '00:00');
        tomorrowPrayers['العشاء'] = _parseApiTimeToTomorrow(data['Isha'] ?? '00:00');

        await _scheduleAllPrayerNotifications(tomorrowPrayers);
        print("✅ Tomorrow's prayers scheduled");
      }
    } catch (e) {
      print("❌ Error fetching tomorrow's prayers: $e");
    }
  }

  DateTime _parseApiTimeToTomorrow(String hhmm24) {
    final parsed = DateFormat("HH:mm").parse(hhmm24);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, parsed.hour, parsed.minute);
  }


}
