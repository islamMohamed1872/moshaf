import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/views/home/home_screen.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../../controllers/prayer_times/prayer_times_cubit.dart';
import '../landing/landing_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Eid Al-Adha Screen — redesigned with Rafeq character assets
// ─────────────────────────────────────────────────────────────────────────────
//
// Add the generated images to your Flutter assets folder like this:
//
// assets/images/rafeq_sheep_hero.png
// assets/images/rafeq_sheep_hug.png
// assets/images/rafeq_lantern_sheep.png
// assets/images/rafeq_eid_sign.png
// assets/images/rafeq_dua.png
// assets/images/rafeq_reading.png
//
// Then register them in pubspec.yaml:
//
// flutter:
//   assets:
//     - assets/images/

// ─────────────────────────────────────────────────────────────────────────────
//  Shared palette
// ─────────────────────────────────────────────────────────────────────────────

const Color _heroBg = Color(0xFF071B14);
const Color _heroBg2 = Color(0xFF0D2B20);
const Color _heroAccent = Color(0xFFD4AF37);
const Color _heroCream = Color(0xFFFFF1C7);
const Color _heroSub = Color(0xFF8CD6A4);
const Color _sand = Color(0xFFEED8A8);

const List<String> _arabicHijriMonths = [
  'مُحَرَّم',
  'صَفَر',
  'رَبيعُ الأوَّل',
  'رَبيعُ الآخِر',
  'جُمادى الأُولَى',
  'جُمادى الآخِرَة',
  'رَجَب',
  'شَعْبان',
  'رَمَضان',
  'شَوَّال',
  'ذُو القَعْدَةِ',
  'ذُو الحِجَّة',
];

String _toArabicDigits(String value) {
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

  var result = value;
  map.forEach((key, val) => result = result.replaceAll(key, val));
  return result;
}

String _formatArabicDayMonth(DateTime date) {
  return _toArabicDigits(DateFormat('d MMMM', 'ar').format(date));
}

String _formatArabicFullDate(DateTime date) {
  return _toArabicDigits(DateFormat('EEEE، d MMMM y', 'ar').format(date));
}

String _formatHijriDate(DateTime date) {
  final hijri = HijriCalendar.fromDate(date);
  final month = _arabicHijriMonths[hijri.hMonth - 1];
  return '${_toArabicDigits(hijri.hDay.toString())} $month ${_toArabicDigits(hijri.hYear.toString())} هـ';
}

String _formatHijriDayMonth(DateTime date) {
  final hijri = HijriCalendar.fromDate(date);
  final month = _arabicHijriMonths[hijri.hMonth - 1];
  return '${_toArabicDigits(hijri.hDay.toString())} $month';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

const String _assetHero = 'assets/images/rafeq_sheep_hero.png';
const String _assetHug = 'assets/images/rafeq_sheep_hug.png';
const String _assetLantern = 'assets/images/rafeq_lantern_sheep.png';
const String _assetReading = 'assets/images/rafeq_reading.png';

// ─────────────────────────────────────────────────────────────────────────────
//  EidAlAdhaScreen
// ─────────────────────────────────────────────────────────────────────────────

class EidAlAdhaScreen extends StatefulWidget {
  const EidAlAdhaScreen({super.key});

  @override
  State<EidAlAdhaScreen> createState() => _EidAlAdhaScreenState();
}

class _EidAlAdhaScreenState extends State<EidAlAdhaScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _lanternCtrl;

  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _contentFade;
  late final Animation<double> _heroScale;
  late final Animation<double> _glowValue;

  Timer? _ticker;

  // Estimated Gregorian dates.
  // Keep these values coming from Remote Config/API if your local authority announces different dates.
  final DateTime _eidStart = DateTime(2026, 5, 27);
  final DateTime _eidEnd = DateTime(2026, 5, 30, 23, 59, 59);
  final DateTime _arafahDay = DateTime(2026, 5, 26);

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _heroFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _contentFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.28, 1.0, curve: Curves.easeOut),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _heroScale = Tween<double>(begin: 0.985, end: 1.018).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _glowValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _lanternCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Keep the screen fresh during Arafah + all Eid days.
    // This updates countdown, current Eid day, Gregorian/Hijri date, and status labels.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
      if (_eidPassed) _ticker?.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    _lanternCtrl.dispose();
    super.dispose();
  }

  bool get _isEidNow =>
      !DateTime.now().isBefore(_eidStart) && !DateTime.now().isAfter(_eidEnd);

  bool get _eidNotYet => DateTime.now().isBefore(_eidStart);

  bool get _eidPassed => DateTime.now().isAfter(_eidEnd);

  bool get _isArafahDay {
    final n = DateTime.now();
    return n.year == _arafahDay.year &&
        n.month == _arafahDay.month &&
        n.day == _arafahDay.day;
  }

  (int, int, int, int) get _countdown {
    if (!_eidNotYet) return (0, 0, 0, 0);
    final diff = _eidStart.difference(DateTime.now());
    return (
    diff.inDays,
    diff.inHours % 24,
    diff.inMinutes % 60,
    diff.inSeconds % 60,
    );
  }

  int get _currentEidDayNumber {
    final now = DateTime.now();
    if (now.isBefore(_eidStart) || now.isAfter(_eidEnd)) return 0;
    return now.difference(DateTime(_eidStart.year, _eidStart.month, _eidStart.day)).inDays + 1;
  }

  String get _heroBadgeLabel {
    if (_isArafahDay) return 'اليوم يوم عرفة';

    final eidDay = _currentEidDayNumber;
    if (eidDay == 1) return 'اليوم يوم النحر';
    if (eidDay > 1) return 'اليوم ${_toArabicDigits(eidDay.toString())} من العيد';

    return _formatHijriDayMonth(DateTime.now());
  }

  String _buildLocationLabel(PrayerTimesCubit prayerCubit) {
    final city = prayerCubit.translateToArabic(prayerCubit.city.trim());
    final country = prayerCubit.translateToArabic(prayerCubit.country.trim());

    if (city.isEmpty && country.isEmpty) return 'موقعك الحالي';
    if (city.isNotEmpty && country.isNotEmpty) return '$city، $country';
    return city.isNotEmpty ? city : country;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().isDark;
    final gold = AppColors.isGoldMode;

    final Color pageBg = gold
        ? const Color(AppColors.goldBackground)
        : (isDark ? const Color(AppColors.scaffoldBg) : const Color(0xFFF5F3EA));
    final Color cardBg = gold
        ? const Color(0xFFF8ECD2)
        : (isDark ? const Color(0xFF14231C) : Colors.white);
    final Color cardBorder = gold
        ? const Color(AppColors.goldBorder)
        : (isDark ? const Color(0xFF294437) : const Color(0xFFE3DCC6));
    final Color primaryClr = gold
        ? const Color(AppColors.goldPrimary)
        : const Color(AppColors.mainGreen);
    final Color textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : const Color(0xFF172B1E));
    final Color mutedClr = gold
        ? const Color(AppColors.goldText).withOpacity(0.58)
        : (isDark ? const Color(0xFF8FB29B) : const Color(0xFF65806C));

    final prayerCubit = context.watch<PrayerTimesCubit>();
    final locationLabel = _buildLocationLabel(prayerCubit);
    final todayGregorianLabel = _formatArabicFullDate(DateTime.now());
    final todayHijriLabel = _formatHijriDate(DateTime.now());
    final eidStartLabel = _formatArabicDayMonth(_eidStart);
    final eidEndLabel = _formatArabicDayMonth(_eidEnd);

    return Scaffold(
      backgroundColor: pageBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _lanternCtrl,
              builder: (_, __) => CustomPaint(
                painter: _FloatingLightsPainter(_lanternCtrl.value, primaryClr),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Row(
                    children: [
                      _SkipButton(textClr: textClr, cardBorder: cardBorder),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _heroFade,
                          child: SlideTransition(
                            position: _heroSlide,
                            child: _AdhaHeroBand(
                              floatCtrl: _floatCtrl,
                              glowCtrl: _glowCtrl,
                              shimmerCtrl: _shimmerCtrl,
                              heroScale: _heroScale,
                              glowValue: _glowValue,
                              isArafahDay: _isArafahDay,
                              locationLabel: locationLabel,
                              badgeLabel: _heroBadgeLabel,
                              todayGregorianLabel: todayGregorianLabel,
                              todayHijriLabel: todayHijriLabel,
                              eidStartLabel: eidStartLabel,
                              eidEndLabel: eidEndLabel,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        FadeTransition(
                          opacity: _contentFade,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.w),
                            child: Column(
                              children: [
                                if (_eidNotYet)
                                  _CountdownBanner(
                                    countdown: _countdown,
                                    primaryClr: primaryClr,
                                    textClr: textClr,
                                    mutedClr: mutedClr,
                                    cardBg: cardBg,
                                    cardBorder: cardBorder,
                                  )
                                else
                                  _StatusBanner(
                                    isNow: _isEidNow,
                                    primaryClr: primaryClr,
                                    textClr: textClr,
                                    mutedClr: mutedClr,
                                    cardBg: cardBg,
                                    cardBorder: cardBorder,
                                  ),
                                SizedBox(height: 14.h),
                                _QuickActionsGrid(
                                  primaryClr: primaryClr,
                                  textClr: textClr,
                                  mutedClr: mutedClr,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                ),
                                SizedBox(height: 14.h),
                                _GreetingCard(
                                  primaryClr: primaryClr,
                                  textClr: textClr,
                                  mutedClr: mutedClr,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                ),
                                SizedBox(height: 14.h),
                                _SectionCard(
                                  label: 'آية كريمة',
                                  icon: Icons.menu_book_rounded,
                                  primaryClr: primaryClr,
                                  textClr: textClr,
                                  mutedClr: mutedClr,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
                                    child: Column(
                                      children: [
                                        Text(
                                          'فَصَلِّ لِرَبِّكَ وَانْحَرْ',
                                          style: AppTextStyles.madB20(context, color: primaryClr),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          'سورة الكوثر — ٢',
                                          style: AppTextStyles.madReg12(context, color: mutedClr),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                _SectionCard(
                                  label: 'أيام الحج والعيد',
                                  icon: Icons.calendar_month_rounded,
                                  primaryClr: primaryClr,
                                  textClr: textClr,
                                  mutedClr: mutedClr,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  child: Padding(
                                    padding: EdgeInsets.all(14.w),
                                    child: _AdhaDaysTimeline(
                                      arafahDay: _arafahDay,
                                      eidStart: _eidStart,
                                      primaryClr: primaryClr,
                                      textClr: textClr,
                                      mutedClr: mutedClr,
                                      cardBorder: cardBorder,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                _RafeqTipCard(
                                  primaryClr: primaryClr,
                                  textClr: textClr,
                                  mutedClr: mutedClr,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                ),
                                SizedBox(height: 14.h),
                                _SectionCard(
                                  label: 'أعمال يوم العيد',
                                  icon: Icons.checklist_rtl_rounded,
                                  primaryClr: primaryClr,
                                  textClr: textClr,
                                  mutedClr: mutedClr,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                    child: Column(
                                      children: [
                                        _SunnahItem(number: '١', text: 'صلاة العيد والاستماع للخطبة', primaryClr: primaryClr, textClr: textClr),
                                        _SunnahItem(number: '٢', text: 'التكبير وإظهار الفرح بحدود الأدب', primaryClr: primaryClr, textClr: textClr),
                                        _SunnahItem(number: '٣', text: 'الأضحية بعد صلاة العيد لمن تيسّر له', primaryClr: primaryClr, textClr: textClr),
                                        _SunnahItem(number: '٤', text: 'توزيع جزء من الأضحية على الأهل والمحتاجين', primaryClr: primaryClr, textClr: textClr),
                                        _SunnahItem(number: '٥', text: 'صلة الرحم وتبادل التهنئة والدعاء', primaryClr: primaryClr, textClr: textClr, isLast: true),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                _SectionCard(
                                  label: 'دعاء العيد',
                                  icon: Icons.volunteer_activism_rounded,
                                  primaryClr: primaryClr,
                                  textClr: textClr,
                                  mutedClr: mutedClr,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
                                    child: Column(
                                      children: [
                                        Text(
                                          'تَقَبَّلَ اللهُ مِنَّا وَمِنكُم',
                                          style: AppTextStyles.madB20(context, color: primaryClr),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 10.h),
                                        Text(
                                          'اللَّهُمَّ اجْعَلْ هَذَا العِيدَ فَرَجًا وَرَحْمَةً\nوَتَقَبَّلْ مِنَّا صَالِحَ الأَعْمَال',
                                          style: AppTextStyles.madReg16(context, color: textClr),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 14.h),
                                        _CopyButton(
                                          label: 'نسخ الدعاء',
                                          value: 'اللَّهُمَّ اجْعَلْ هَذَا العِيدَ فَرَجًا وَرَحْمَةً\nوَتَقَبَّلْ مِنَّا صَالِحَ الأَعْمَال',
                                          primaryClr: primaryClr,
                                          cardBorder: cardBorder,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                _SectionCard(
                                  label: 'تكبيرات العيد',
                                  icon: Icons.campaign_rounded,
                                  primaryClr: primaryClr,
                                  textClr: textClr,
                                  mutedClr: mutedClr,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
                                    child: Column(
                                      children: [
                                        Text(
                                          'اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، اللهُ أَكْبَرُ\nلَا إِلَهَ إِلَّا اللهُ\nاللهُ أَكْبَرُ، اللهُ أَكْبَرُ\nوَلِلَّهِ الْحَمْدُ',
                                          style: AppTextStyles.madReg16(context, color: textClr),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 14.h),
                                        Text(
                                          'التكبير من أعظم شعائر أيام العيد وأيام التشريق',
                                          style: AppTextStyles.madReg12(context, color: mutedClr),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 14.h),
                                        _CopyButton(
                                          label: 'نسخ التكبيرات',
                                          value: 'اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، اللهُ أَكْبَرُ\nلَا إِلَهَ إِلَّا اللهُ\nاللهُ أَكْبَرُ، اللهُ أَكْبَرُ\nوَلِلَّهِ الْحَمْدُ',
                                          primaryClr: primaryClr,
                                          cardBorder: cardBorder,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                _SectionCard(
                                  label: 'أيام التشريق',
                                  icon: Icons.auto_awesome_rounded,
                                  primaryClr: primaryClr,
                                  textClr: textClr,
                                  mutedClr: mutedClr,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 18.h),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'أيام ذكرٍ وشكر',
                                                style: AppTextStyles.madB16(context, color: primaryClr),
                                              ),
                                              SizedBox(height: 6.h),
                                              Text(
                                                'استكثر فيها من التكبير والذكر، واجعل رفيق يذكّرك بأذكارك ومواقيت الصلاة.',
                                                style: AppTextStyles.madReg14(context, color: textClr.withOpacity(0.82)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        _RoundedAsset(
                                          asset: _assetReading,
                                          width: 92.w,
                                          height: 92.w,
                                          fit: BoxFit.contain,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 34.h),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Skip button
// ─────────────────────────────────────────────────────────────────────────────

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.textClr, required this.cardBorder});

  final Color textClr;
  final Color cardBorder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (FirebaseAuth.instance.currentUser == null) {
          navigateAndFinish(context, LandingScreen());
        } else {
          navigateAndFinish(context, HomeScreen());
        }
      },
      borderRadius: BorderRadius.circular(38),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 6, horizontal: 19),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(38),
          color: Colors.white.withOpacity(0.03),
          border: Border.all(color: cardBorder),
        ),
        child: Text('تخطي', style: AppTextStyles.madReg14(context, color: textClr)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hero band
// ─────────────────────────────────────────────────────────────────────────────

class _AdhaHeroBand extends StatelessWidget {
  const _AdhaHeroBand({
    required this.floatCtrl,
    required this.glowCtrl,
    required this.shimmerCtrl,
    required this.heroScale,
    required this.glowValue,
    required this.isArafahDay,
    required this.locationLabel,
    required this.badgeLabel,
    required this.todayGregorianLabel,
    required this.todayHijriLabel,
    required this.eidStartLabel,
    required this.eidEndLabel,
  });

  final AnimationController floatCtrl;
  final AnimationController glowCtrl;
  final AnimationController shimmerCtrl;
  final Animation<double> heroScale;
  final Animation<double> glowValue;
  final bool isArafahDay;
  final String locationLabel;
  final String badgeLabel;
  final String todayGregorianLabel;
  final String todayHijriLabel;
  final String eidStartLabel;
  final String eidEndLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_heroBg, _heroBg2],
        ),
        boxShadow: [
          BoxShadow(
            color: _heroAccent.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _AdhaPatternPainter())),
          Positioned.fill(child: CustomPaint(painter: _StarfieldPainter(_heroAccent))),
          Positioned(
            top: 12.h,
            right: 18.w,
            child: _LocationPill(label: locationLabel),
          ),
          Positioned(
            top: 70.h,
            left: -34.w,
            child: _GlowCircle(size: 150.w, opacity: 0.18),
          ),
          Positioned(
            bottom: -42.h,
            right: -20.w,
            child: _SandHills(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 1.5,
            child: AnimatedBuilder(
              animation: shimmerCtrl,
              builder: (_, __) => ShaderMask(
                shaderCallback: (rect) {
                  final dx = shimmerCtrl.value;
                  return LinearGradient(
                    begin: Alignment(dx * 3 - 1.5, 0),
                    end: Alignment(dx * 3 - 0.5, 0),
                    colors: [
                      _heroAccent.withOpacity(0.0),
                      _heroAccent.withOpacity(0.8),
                      _heroAccent.withOpacity(0.0),
                    ],
                  ).createShader(rect);
                },
                child: Container(color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(22.w, 32.h, 22.w, 24.h),
            child: Column(
              children: [
                SizedBox(height: 26.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 11,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MiniBadge(label: badgeLabel),
                          SizedBox(height: 10.h),
                          Text(
                            'عيد\nالأضحى\nالمبارك',
                            style: TextStyle(
                              fontSize: 35.sp,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                              color: _heroCream,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          SizedBox(height: 10.h),
                          Container(
                            width: 92.w,
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _heroAccent.withOpacity(0.0),
                                  _heroAccent,
                                  _heroAccent.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'تقبّل الله منا ومنكم صالح الأعمال',
                            style: AppTextStyles.madReg12(
                              context,
                              color: Colors.white.withOpacity(0.84),
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            todayGregorianLabel,
                            style: AppTextStyles.madReg10(
                              context,
                              color: Colors.white.withOpacity(0.66),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            todayHijriLabel,
                            style: AppTextStyles.madReg10(
                              context,
                              color: _heroSub.withOpacity(0.92),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      flex: 12,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([floatCtrl, glowCtrl]),
                        builder: (_, __) => Transform.scale(
                          scale: heroScale.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 190.w,
                                height: 190.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _heroAccent.withOpacity(0.22 + glowValue.value * 0.12),
                                      blurRadius: 46,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              _RoundedAsset(
                                asset: _assetHero,
                                width: 205.w,
                                height: 205.w,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                _HeroInfoStrip(startLabel: eidStartLabel, endLabel: eidEndLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 150.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: _heroAccent.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, color: _heroAccent, size: 14.sp),
          SizedBox(width: 5.w),
          Flexible(child: Text(label, style: AppTextStyles.madReg11(context, color: _heroCream), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: _heroAccent.withOpacity(0.14),
        border: Border.all(color: _heroAccent.withOpacity(0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: _heroAccent, size: 13.sp),
          SizedBox(width: 5.w),
          Text(label, style: AppTextStyles.madReg11(context, color: _heroCream)),
        ],
      ),
    );
  }
}

class _HeroInfoStrip extends StatelessWidget {
  const _HeroInfoStrip({required this.startLabel, required this.endLabel});

  final String startLabel;
  final String endLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: _heroAccent.withOpacity(0.32)),
          ),
          child: Row(
            children: [
              _HeroChip(label: startLabel, sub: 'بداية العيد', icon: Icons.flag_rounded),
              SizedBox(width: 8.w),
              _HeroChip(label: endLabel, sub: 'آخر أيام التشريق', icon: Icons.nightlight_round),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.sub, required this.icon});

  final String label;
  final String sub;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _heroAccent.withOpacity(0.13),
              border: Border.all(color: _heroAccent.withOpacity(0.30)),
            ),
            child: Icon(icon, size: 16.sp, color: _heroAccent),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.madB14(context, color: _heroCream)),
                SizedBox(height: 1.h),
                Text(sub, style: AppTextStyles.madReg10(context, color: _heroSub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Countdown / status
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownBanner extends StatelessWidget {
  const _CountdownBanner({
    required this.countdown,
    required this.primaryClr,
    required this.textClr,
    required this.mutedClr,
    required this.cardBg,
    required this.cardBorder,
  });

  final (int, int, int, int) countdown;
  final Color primaryClr;
  final Color textClr;
  final Color mutedClr;
  final Color cardBg;
  final Color cardBorder;

  @override
  Widget build(BuildContext context) {
    final (d, h, m, s) = countdown;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            cardBg,
            primaryClr.withOpacity(0.055),
          ],
        ),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryClr.withOpacity(0.10),
                ),
                child: Icon(Icons.hourglass_top_rounded, color: primaryClr, size: 17.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('العد التنازلي لعيد الأضحى', style: AppTextStyles.madB14(context, color: textClr)),
                    SizedBox(height: 1.h),
                    Text('استعد لأفضل أيام الذكر والشكر', style: AppTextStyles.madReg11(context, color: mutedClr)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CountUnit(value: d.toString().padLeft(2, '0'), label: 'يوم', primaryClr: primaryClr, mutedClr: mutedClr),
              _Colon(primaryClr: primaryClr),
              _CountUnit(value: h.toString().padLeft(2, '0'), label: 'ساعة', primaryClr: primaryClr, mutedClr: mutedClr),
              _Colon(primaryClr: primaryClr),
              _CountUnit(value: m.toString().padLeft(2, '0'), label: 'دقيقة', primaryClr: primaryClr, mutedClr: mutedClr),
              _Colon(primaryClr: primaryClr),
              _CountUnit(value: s.toString().padLeft(2, '0'), label: 'ثانية', primaryClr: primaryClr, mutedClr: mutedClr),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountUnit extends StatelessWidget {
  const _CountUnit({
    required this.value,
    required this.label,
    required this.primaryClr,
    required this.mutedClr,
  });

  final String value;
  final String label;
  final Color primaryClr;
  final Color mutedClr;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54.w,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: primaryClr.withOpacity(0.09),
            border: Border.all(color: primaryClr.withOpacity(0.22)),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.madB20(context, color: primaryClr),
          ),
        ),
        SizedBox(height: 5.h),
        Text(label, style: AppTextStyles.madReg10(context, color: mutedClr)),
      ],
    );
  }
}

class _Colon extends StatelessWidget {
  const _Colon({required this.primaryClr});
  final Color primaryClr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Text(
        ':',
        style: TextStyle(color: primaryClr, fontSize: 22.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.isNow,
    required this.primaryClr,
    required this.textClr,
    required this.mutedClr,
    required this.cardBg,
    required this.cardBorder,
  });

  final bool isNow;
  final Color primaryClr;
  final Color textClr;
  final Color mutedClr;
  final Color cardBg;
  final Color cardBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isNow ? primaryClr.withOpacity(0.10) : cardBg,
        border: Border.all(
          color: isNow ? primaryClr.withOpacity(0.5) : cardBorder,
          width: isNow ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: primaryClr.withOpacity(0.12)),
            child: Icon(isNow ? Icons.celebration_rounded : Icons.auto_awesome_rounded, color: primaryClr, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isNow ? 'نحن الآن في أيام العيد' : 'انتهى العيد', style: AppTextStyles.madReg12(context, color: mutedClr)),
                SizedBox(height: 2.h),
                Text(
                  isNow ? 'عيد أضحى مبارك! كل عام وأنتم بخير' : 'نسأل الله أن يعيده علينا بالخير',
                  style: AppTextStyles.madB16(context, color: textClr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Quick actions
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.primaryClr,
    required this.textClr,
    required this.mutedClr,
    required this.cardBg,
    required this.cardBorder,
  });

  final Color primaryClr;
  final Color textClr;
  final Color mutedClr;
  final Color cardBg;
  final Color cardBorder;

  static const List<_ActionItem> _items = [
    _ActionItem(title: 'أعمال\nالعيد', subtitle: 'ما يُستحب فعله', icon: Icons.checklist_rtl_rounded),
    _ActionItem(title: 'سنن\nالعيد', subtitle: 'تعرّف عليها', icon: Icons.menu_book_rounded),
    _ActionItem(title: 'التكبيرات', subtitle: 'كبّر واذكر الله', icon: Icons.campaign_rounded),
    _ActionItem(title: 'دعاء', subtitle: 'أدعية مأثورة', icon: Icons.volunteer_activism_rounded),
    _ActionItem(title: 'أيام\nالتشريق', subtitle: 'فضائل وأعمال', icon: Icons.auto_awesome_rounded),
    _ActionItem(title: 'مواقيت\nالصلاة', subtitle: 'حسب منطقتك', icon: Icons.calendar_today_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        childAspectRatio: 0.86,
      ),
      itemBuilder: (_, i) {
        final item = _items[i];
        return Container(
          padding: EdgeInsets.all(11.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: cardBg,
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: primaryClr.withOpacity(0.09),
                  border: Border.all(color: primaryClr.withOpacity(0.20)),
                ),
                child: Icon(item.icon, color: primaryClr, size: 18.sp),
              ),
              const Spacer(),
              Text(
                item.title,
                style: AppTextStyles.madB14(context, color: textClr),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                item.subtitle,
                style: AppTextStyles.madReg10(context, color: mutedClr),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionItem {
  const _ActionItem({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Greeting card
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingCard extends StatefulWidget {
  const _GreetingCard({
    required this.primaryClr,
    required this.textClr,
    required this.mutedClr,
    required this.cardBg,
    required this.cardBorder,
  });

  final Color primaryClr;
  final Color textClr;
  final Color mutedClr;
  final Color cardBg;
  final Color cardBorder;

  @override
  State<_GreetingCard> createState() => _GreetingCardState();
}

class _GreetingCardState extends State<_GreetingCard> {
  int _selected = 0;

  static const _greetings = [
    'عيد أضحى مبارك، تقبّل الله منا ومنكم صالح الأعمال وجعل أيامكم خيرًا وبركة 🐑',
    'كل عام وأنتم بخير، أعاده الله عليكم بالفرح والسكينة وصالح الطاعات 🤲',
    'تقبّل الله طاعتكم وأضحيتكم، وجعل عيدكم مليئًا بالرحمة والود ✨',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: widget.cardBg,
        border: Border.all(color: widget.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              color: widget.primaryClr.withOpacity(0.07),
              border: Border(bottom: BorderSide(color: widget.cardBorder)),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite_rounded, size: 14.sp, color: widget.primaryClr),
                SizedBox(width: 8.w),
                Text('رسائل التهنئة', style: AppTextStyles.madReg12(context, color: widget.primaryClr)),
                const Spacer(),
                Text('${_selected + 1} / ${_greetings.length}', style: AppTextStyles.madReg10(context, color: widget.mutedClr)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
            child: Row(
              children: [
                _RoundedAsset(asset: _assetHug, width: 82.w, height: 82.w, fit: BoxFit.contain),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    _greetings[_selected],
                    style: AppTextStyles.madReg16(context, color: widget.textClr),
                    textAlign: TextAlign.start,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
            child: Row(
              children: [
                Row(
                  children: List.generate(
                    _greetings.length,
                        (i) => GestureDetector(
                      onTap: () => setState(() => _selected = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsetsDirectional.only(end: 4.w),
                        width: _selected == i ? 18.w : 6.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: _selected == i ? widget.primaryClr : widget.primaryClr.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                _SmallButton(
                  label: 'نسخ',
                  icon: Icons.copy_rounded,
                  primaryClr: widget.primaryClr,
                  textClr: widget.textClr,
                  cardBorder: widget.cardBorder,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _greetings[_selected]));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم نسخ التهنئة', style: AppTextStyles.madReg14(context, color: Colors.white)),
                        backgroundColor: widget.primaryClr,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                SizedBox(width: 8.w),
                _SmallButton(
                  label: 'التالي',
                  icon: Icons.arrow_forward_ios_rounded,
                  primaryClr: widget.primaryClr,
                  textClr: widget.textClr,
                  cardBorder: widget.cardBorder,
                  onTap: () => setState(() => _selected = (_selected + 1) % _greetings.length),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.icon,
    required this.primaryClr,
    required this.textClr,
    required this.cardBorder,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color primaryClr;
  final Color textClr;
  final Color cardBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Text(label, style: AppTextStyles.madReg12(context, color: textClr)),
            SizedBox(width: 4.w),
            Icon(icon, size: 12.sp, color: primaryClr),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section shell
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.label,
    required this.icon,
    required this.primaryClr,
    required this.textClr,
    required this.mutedClr,
    required this.cardBg,
    required this.cardBorder,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Color primaryClr;
  final Color textClr;
  final Color mutedClr;
  final Color cardBg;
  final Color cardBorder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardBg,
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              color: primaryClr.withOpacity(0.07),
              border: Border(bottom: BorderSide(color: cardBorder)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15.sp, color: primaryClr),
                SizedBox(width: 8.w),
                Text(label, style: AppTextStyles.madReg12(context, color: primaryClr)),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Timeline days
// ─────────────────────────────────────────────────────────────────────────────

class _AdhaDaysTimeline extends StatelessWidget {
  const _AdhaDaysTimeline({
    required this.arafahDay,
    required this.eidStart,
    required this.primaryClr,
    required this.textClr,
    required this.mutedClr,
    required this.cardBorder,
  });

  final DateTime arafahDay;
  final DateTime eidStart;
  final Color primaryClr;
  final Color textClr;
  final Color mutedClr;
  final Color cardBorder;

  List<({DateTime date, String label})> get _days => [
    (date: arafahDay.subtract(const Duration(days: 1)), label: 'يوم التروية'),
    (date: arafahDay, label: 'يوم عرفة'),
    (date: eidStart, label: 'عيد الأضحى'),
    (date: eidStart.add(const Duration(days: 1)), label: 'التشريق ١'),
    (date: eidStart.add(const Duration(days: 2)), label: 'التشريق ٢'),
    (date: eidStart.add(const Duration(days: 3)), label: 'التشريق ٣'),
  ];

  bool _isToday(DateTime date) => _isSameDay(DateTime.now(), date);

  bool _isPast(DateTime date) {
    return DateTime.now().isAfter(DateTime(date.year, date.month, date.day, 23, 59, 59));
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _days.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (_, i) {
        final item = _days[i];
        final today = _isToday(item.date);
        final past = _isPast(item.date);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: today
                ? primaryClr.withOpacity(0.13)
                : past
                ? primaryClr.withOpacity(0.035)
                : primaryClr.withOpacity(0.065),
            border: Border.all(
              color: today ? primaryClr : primaryClr.withOpacity(past ? 0.10 : 0.18),
              width: today ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: today ? primaryClr : primaryClr.withOpacity(0.12),
                    ),
                    child: Center(
                      child: past && !today
                          ? Icon(Icons.check, size: 13.sp, color: primaryClr.withOpacity(0.55))
                          : Text(
                        _toArabicDigits(HijriCalendar.fromDate(item.date).hDay.toString()),
                        style: AppTextStyles.madB12(context, color: today ? Colors.white : primaryClr),
                      ),
                    ),
                  ),
                  if (today) ...[
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(color: primaryClr, borderRadius: BorderRadius.circular(20)),
                      child: Text('اليوم', style: AppTextStyles.madReg10(context, color: Colors.white)),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              Text(
                item.label,
                style: AppTextStyles.madB14(context, color: today ? primaryClr : textClr.withOpacity(past ? 0.45 : 1)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.h),
              Text('${_formatArabicDayMonth(item.date)} — ${_formatHijriDayMonth(item.date)}', style: AppTextStyles.madReg10(context, color: mutedClr.withOpacity(past ? 0.5 : 1))),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Rafeq tip card
// ─────────────────────────────────────────────────────────────────────────────

class _RafeqTipCard extends StatelessWidget {
  const _RafeqTipCard({
    required this.primaryClr,
    required this.textClr,
    required this.mutedClr,
    required this.cardBg,
    required this.cardBorder,
  });

  final Color primaryClr;
  final Color textClr;
  final Color mutedClr;
  final Color cardBg;
  final Color cardBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            primaryClr.withOpacity(0.12),
            cardBg,
          ],
        ),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          _RoundedAsset(asset: _assetLantern, width: 96.w, height: 96.w, fit: BoxFit.contain),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('رفيقك في أيام العيد', style: AppTextStyles.madB16(context, color: primaryClr)),
                SizedBox(height: 5.h),
                Text(
                  'تابع العد التنازلي، انسخ التهاني والتكبيرات، وخلي رفيق يذكّرك بأعمال يوم العيد.',
                  style: AppTextStyles.madReg14(context, color: textClr.withOpacity(0.82)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  List item / copy button
// ─────────────────────────────────────────────────────────────────────────────

class _SunnahItem extends StatelessWidget {
  const _SunnahItem({
    required this.number,
    required this.text,
    required this.primaryClr,
    required this.textClr,
    this.isLast = false,
  });

  final String number;
  final String text;
  final Color primaryClr;
  final Color textClr;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: primaryClr.withOpacity(0.10)),
            child: Center(child: Text(number, style: AppTextStyles.madB12(context, color: primaryClr))),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 3.h),
              child: Text(text, style: AppTextStyles.madReg14(context, color: textClr)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({
    required this.label,
    required this.value,
    required this.primaryClr,
    required this.cardBorder,
  });

  final String label;
  final String value;
  final Color primaryClr;
  final Color cardBorder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم النسخ', style: AppTextStyles.madReg14(context, color: Colors.white)),
            backgroundColor: primaryClr,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryClr.withOpacity(0.35)),
          color: primaryClr.withOpacity(0.07),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy_rounded, size: 14.sp, color: primaryClr),
            SizedBox(width: 6.w),
            Text(label, style: AppTextStyles.madReg12(context, color: primaryClr)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Asset helper with fallback
// ─────────────────────────────────────────────────────────────────────────────

class _RoundedAsset extends StatelessWidget {
  const _RoundedAsset({
    required this.asset,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _heroAccent.withOpacity(0.10),
          border: Border.all(color: _heroAccent.withOpacity(0.25)),
        ),
        child: Icon(Icons.image_rounded, color: _heroAccent, size: min(width, height) * 0.28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Decorative widgets / painters
// ─────────────────────────────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _heroAccent.withOpacity(opacity),
        boxShadow: [
          BoxShadow(
            color: _heroAccent.withOpacity(opacity),
            blurRadius: 80,
            spreadRadius: 26,
          ),
        ],
      ),
    );
  }
}

class _SandHills extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(260.w, 110.h),
      painter: _SandHillsPainter(),
    );
  }
}

class _SandHillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _sand.withOpacity(0.08);
    final path = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.40, size.width * 0.55, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.93, size.width, size.height * 0.62)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AdhaPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _heroAccent.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width * 0.82, size.height * 0.30);
    for (int i = 0; i < 12; i++) {
      final r = 18.0 + i * 6;
      canvas.drawCircle(center, r, paint);
    }

    final arch = Path()
      ..moveTo(size.width * 0.16, size.height * 0.22)
      ..quadraticBezierTo(size.width * 0.50, -size.height * 0.02, size.width * 0.84, size.height * 0.22)
      ..lineTo(size.width * 0.84, size.height * 0.75)
      ..lineTo(size.width * 0.16, size.height * 0.75)
      ..close();

    canvas.drawPath(
      arch,
      Paint()
        ..color = _heroAccent.withOpacity(0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter(this.color);
  final Color color;

  static final _stars = List.generate(54, (i) {
    final r = Random(i * 997 + 3);
    return (
    x: r.nextDouble(),
    y: r.nextDouble() * 0.84,
    size: 0.5 + r.nextDouble() * 1.7,
    opacity: 0.12 + r.nextDouble() * 0.5,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        Paint()..color = color.withOpacity(s.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter oldDelegate) => false;
}

class _FloatingLightsPainter extends CustomPainter {
  _FloatingLightsPainter(this.progress, this.color);

  final double progress;
  final Color color;

  static final _specs = List.generate(18, (i) {
    final r = Random(i * 137 + 41);
    return (
    x: r.nextDouble(),
    phase: r.nextDouble(),
    speed: 0.005 + r.nextDouble() * 0.010,
    size: 2.0 + r.nextDouble() * 4.4,
    swing: 8.0 + r.nextDouble() * 14,
    opacity: 0.04 + r.nextDouble() * 0.10,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _specs) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final y = size.height * (1.0 - t);
      final x = size.width * p.x + sin(t * 2 * pi * 1.4 + p.phase * 10) * p.swing;
      if (y < -20) continue;
      canvas.drawCircle(
        Offset(x, y),
        p.size,
        Paint()
          ..color = color.withOpacity(p.opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_FloatingLightsPainter oldDelegate) => oldDelegate.progress != progress;
}
