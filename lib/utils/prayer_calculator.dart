

import 'dart:math';
import 'package:geocoding/geocoding.dart';

/// ----------------------------------------------------------
/// ENUMS & CONFIG
/// ----------------------------------------------------------

enum PrayerMethod { egypt, ummAlQura, mwl, isna, karachi, turkey }

class PrayerMethodConfig {
  final double fajrAngle;
  final double ishaAngle;
  final int? ishaInterval; // minutes after Maghrib (Umm al-Qura)

  PrayerMethodConfig({
    required this.fajrAngle,
    required this.ishaAngle,
    this.ishaInterval,
  });
}

/// ----------------------------------------------------------
/// DETECT COUNTRY → CHOOSE METHOD
/// ----------------------------------------------------------

Future<String?> getCountryCode(double lat, double lng) async {
  try {
    final places = await placemarkFromCoordinates(lat, lng);
    return places.isNotEmpty ? places.first.isoCountryCode : null;
  } catch (_) {
    return null;
  }
}

PrayerMethod detectMethod(String cc) {
  cc = cc.toUpperCase();

  if (["SA", "KW", "QA", "AE", "BH", "OM", "YE"].contains(cc))
    return PrayerMethod.ummAlQura;

  if (["EG", "SD"].contains(cc)) return PrayerMethod.egypt;
  if (["TR"].contains(cc)) return PrayerMethod.turkey;
  if (["PK", "IN", "BD", "AF"].contains(cc)) return PrayerMethod.karachi;
  if (["US", "CA"].contains(cc)) return PrayerMethod.isna;

  return PrayerMethod.mwl; // default
}

PrayerMethodConfig getMethodConfig(PrayerMethod m) {
  switch (m) {
    case PrayerMethod.egypt:
      return PrayerMethodConfig(fajrAngle: 19.5, ishaAngle: 17.5);
    case PrayerMethod.ummAlQura:
      return PrayerMethodConfig(
        fajrAngle: 18.5,
        ishaAngle: -1,
        ishaInterval: 90,
      );
    case PrayerMethod.karachi:
      return PrayerMethodConfig(fajrAngle: 18, ishaAngle: 18);
    case PrayerMethod.isna:
      return PrayerMethodConfig(fajrAngle: 15, ishaAngle: 15);
    case PrayerMethod.turkey:
      return PrayerMethodConfig(fajrAngle: 18, ishaAngle: 17);
    case PrayerMethod.mwl:
    default:
      return PrayerMethodConfig(fajrAngle: 18, ishaAngle: 17);
  }
}

/// ----------------------------------------------------------
/// SOLAR CALCULATIONS (Corrected)
/// ----------------------------------------------------------

class PrayerCalculator {
  final double lat;
  final double lng;
  final double tz;
  final DateTime date;

  final double fajrAngle;
  final double ishaAngle;
  final int? ishaInterval;

  static const double sunriseRef = 0.833;

  PrayerCalculator({
    required this.lat,
    required this.lng,
    required this.tz,
    required this.date,
    required this.fajrAngle,
    required this.ishaAngle,
    this.ishaInterval,
  });

  double _degToRad(double d) => d * pi / 180;
  double _radToDeg(double r) => r * 180 / pi;
  double _wrap(double x) => (x % 360 + 360) % 360;

  DateTime _round(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }

  DateTime _makeDate(double hours) {
    hours = (hours % 24 + 24) % 24;
    int h = hours.floor();
    int m = ((hours - h) * 60).round();
    return _round(DateTime(date.year, date.month, date.day, h, m));
  }

  /// Julian Day (proper UTC handling)
  double _julian(DateTime d) {
    final u = d.toUtc();
    int y = u.year;
    int m = u.month;
    double day = u.day + u.hour / 24 + u.minute / 1440;

    if (m <= 2) {
      y -= 1;
      m += 12;
    }

    int A = (y / 100).floor();
    int B = 2 - A + (A / 4).floor();

    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        B -
        1524.5;
  }

  /// Correct sun declination + EoT (verified)
  Map<String, double> _sunData(double jd) {
    double D = jd - 2451545;

    double g = _wrap(357.529 + 0.98560028 * D);
    double q = _wrap(280.459 + 0.98564736 * D);
    double L = _wrap(q + 1.915 * sin(_degToRad(g)) + 0.020 * sin(_degToRad(2 * g)));

    double e = 23.439 - 0.00000036 * D;

    double RA = _radToDeg(
      atan2(cos(_degToRad(e)) * sin(_degToRad(L)), cos(_degToRad(L))),
    ) / 15;

    double decl = _radToDeg(asin(sin(_degToRad(e)) * sin(_degToRad(L))));

    double eqt = q / 15 - RA;

    return {'decl': decl, 'eqt': eqt};
  }

  /// Hour angle
  double _HA(double alt, double decl) {
    double sAlt = sin(_degToRad(alt));
    double sLat = sin(_degToRad(lat));
    double cLat = cos(_degToRad(lat));
    double sDec = sin(_degToRad(decl));
    double cDec = cos(_degToRad(decl));

    double cH = (sAlt - sLat * sDec) / (cLat * cDec);
    cH = cH.clamp(-1.0, 1.0);

    return _radToDeg(acos(cH)) / 15;
  }

  /// Correct Asr solar altitude (Shafi‘i)
  double _asrAltitude(double decl) {
    double x = (lat - decl).abs();
    return _radToDeg(atan(1 / (1 + tan(_degToRad(x)))));
  }

  Map<String, DateTime> compute() {
    double jd = _julian(DateTime(date.year, date.month, date.day, 12));
    final sun = _sunData(jd);

    double decl = sun['decl']!;
    double eqt = sun['eqt']!;

    // solar noon
    double noon = 12 + tz - (lng / 15) - eqt;

    double fajr = noon - _HA(-fajrAngle, decl);
    double sunrise = noon - _HA(-sunriseRef, decl);
    double dhuhr = noon;

    double asr = noon + _HA(_asrAltitude(decl), decl);

    double maghrib = noon + _HA(-sunriseRef, decl);

    double isha = ishaInterval != null
        ? maghrib + ishaInterval! / 60
        : noon + _HA(-ishaAngle, decl);

    /// Midnight + last third
    double fajrNext = fajr < maghrib ? fajr + 24 : fajr;
    double night = fajrNext - maghrib;

    double midnight = maghrib + night / 2;
    double lastThird = maghrib + 2 * night / 3;

    return {
      'الفجر': _makeDate(fajr),
      'الشروق': _makeDate(sunrise),
      'الظهر': _makeDate(dhuhr),
      'العصر': _makeDate(asr),
      'المغرب': _makeDate(maghrib),
      'العشاء': _makeDate(isha),
      'منتصف الليل': _makeDate(midnight),
      'الثلث الاخير': _makeDate(lastThird),
    };
  }
}

/// ----------------------------------------------------------
/// PUBLIC AUTO-METHOD FUNCTION
/// ----------------------------------------------------------

Future<Map<String, DateTime>> computePrayerTimesAuto({
  required double lat,
  required double lng,
  required DateTime date,
}) async {
  final cc = await getCountryCode(lat, lng);
  final method = detectMethod(cc ?? "");
  final cfg = getMethodConfig(method);

  print("🌍 Country = $cc → Method = $method");

  final tz = date.timeZoneOffset.inMinutes / 60;

  final calc = PrayerCalculator(
    lat: lat,
    lng: lng,
    tz: tz,
    date: date,
    fajrAngle: cfg.fajrAngle,
    ishaAngle: cfg.ishaAngle,
    ishaInterval: cfg.ishaInterval,
  );

  return calc.compute();
}
