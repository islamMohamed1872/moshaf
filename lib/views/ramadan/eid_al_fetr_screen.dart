import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/views/home/home_screen.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../landing/landing_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Shared palette
// ─────────────────────────────────────────────────────────────────────────────

const Color _heroBg     = Color(0xFF0A1410);
const Color _heroAccent = Color(0xFFD4AF37);
const Color _heroMoon   = Color(0xFFF5E27A);
const Color _heroSub    = Color(0xFF6DBE8A);
const Color _starDim    = Color(0xFFD4AF37);

// ─────────────────────────────────────────────────────────────────────────────
//  EidAlFitrScreen
// ─────────────────────────────────────────────────────────────────────────────

class EidAlFitrScreen extends StatefulWidget {
  const EidAlFitrScreen({super.key});

  @override
  State<EidAlFitrScreen> createState() => _EidAlFitrScreenState();
}

class _EidAlFitrScreenState extends State<EidAlFitrScreen>
    with TickerProviderStateMixin {

  late final AnimationController _entryCtrl;
  late final AnimationController _lanternCtrl;
  late final AnimationController _moonCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _contentFade;
  late final Animation<double> _moonScale;
  late final Animation<double> _moonGlow;

  // ✅ Simple Timer — fires every second, calls setState
  Timer? _ticker;

  final DateTime _eidStart = DateTime(2026, 3, 20);
  final DateTime _eidEnd   = DateTime(2026, 3, 23, 23, 59, 59);

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _heroFade   = CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.55, curve: Curves.easeOut));
    _heroSlide  = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.55, curve: Curves.easeOut)));
    _contentFade = CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.30, 1.0, curve: Curves.easeOut));

    _lanternCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _moonCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _moonScale   = Tween<double>(begin: 1.0, end: 1.07).animate(CurvedAnimation(parent: _moonCtrl, curve: Curves.easeInOut));
    _moonGlow    = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _moonCtrl, curve: Curves.easeInOut));
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

    // ✅ Start the per-second ticker only while countdown is relevant
    if (_eidNotYet) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
        // Stop ticking once Eid starts
        if (!_eidNotYet) _ticker?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _entryCtrl.dispose();
    _lanternCtrl.dispose();
    _moonCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  bool get _isEidNow  => !DateTime.now().isBefore(_eidStart) && !DateTime.now().isAfter(_eidEnd);
  bool get _eidPassed => DateTime.now().isAfter(_eidEnd);
  bool get _eidNotYet => DateTime.now().isBefore(_eidStart);

  (int, int, int, int) get _countdown {
    if (!_eidNotYet) return (0, 0, 0, 0);
    final diff = _eidStart.difference(DateTime.now());
    return (diff.inDays, diff.inHours % 24, diff.inMinutes % 60, diff.inSeconds % 60);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().isDark;
    final gold   = AppColors.isGoldMode;

    final Color pageBg     = gold ? const Color(AppColors.goldBackground) : (isDark ? const Color(AppColors.scaffoldBg) : const Color(0xFFF4F7F4));
    final Color cardBg     = gold ? const Color(0xFFF5EAD0)               : (isDark ? const Color(0xFF1A2420)           : Colors.white);
    final Color cardBorder = gold ? const Color(AppColors.goldBorder)      : (isDark ? const Color(0xFF2A3D32)           : const Color(0xFFDCEAE0));
    final Color primaryClr = gold ? const Color(AppColors.goldPrimary)     : const Color(AppColors.mainGreen);
    final Color textClr    = gold ? const Color(AppColors.goldText)        : (isDark ? Colors.white                     : const Color(0xFF172B1E));
    final Color mutedClr   = gold ? const Color(AppColors.goldText).withOpacity(0.55) : (isDark ? const Color(0xFF80A892) : const Color(0xFF5A7D69));

    return Scaffold(
      backgroundColor: pageBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _lanternCtrl,
              builder: (_, __) => CustomPaint(painter: _LanternPainter(_lanternCtrl.value, primaryClr)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Row(children: [
                    _SkipButton(textClr: textClr, cardBorder: cardBorder),
                  ]),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(children: [

                      // ── HERO ──────────────────────────────────────────
                      FadeTransition(
                        opacity: _heroFade,
                        child: SlideTransition(
                          position: _heroSlide,
                          child: _HeroBand(
                            moonCtrl: _moonCtrl, moonScale: _moonScale,
                            moonGlow: _moonGlow, shimmerCtrl: _shimmerCtrl,
                          ),
                        ),
                      ),

                      SizedBox(height: 18.h),

                      FadeTransition(
                        opacity: _contentFade,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18.w),
                          child: Column(children: [

                            // ── COUNTDOWN / STATUS ────────────────────
                            if (_eidNotYet)
                              _CountdownBanner(
                                countdown: _countdown,
                                primaryClr: primaryClr, textClr: textClr,
                                mutedClr: mutedClr, cardBg: cardBg, cardBorder: cardBorder,
                              )
                            else
                              _StatusBanner(
                                isNow: _isEidNow,
                                primaryClr: primaryClr, textClr: textClr,
                                mutedClr: mutedClr, cardBg: cardBg, cardBorder: cardBorder,
                              ),

                            SizedBox(height: 14.h),

                            // ── GREETING CARD ─────────────────────────
                            _GreetingCard(
                              primaryClr: primaryClr, textClr: textClr,
                              mutedClr: mutedClr, cardBg: cardBg, cardBorder: cardBorder,
                            ),

                            SizedBox(height: 14.h),

                            // ── QURAN VERSE ───────────────────────────
                            _SectionCard(
                              label: "آية كريمة",
                              primaryClr: primaryClr, textClr: textClr,
                              mutedClr: mutedClr, cardBg: cardBg, cardBorder: cardBorder,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
                                child: Column(children: [
                                  Text(
                                    "وَلِتُكْمِلُوا الْعِدَّةَ وَلِتُكَبِّرُوا اللَّهَ عَلَىٰ مَا هَدَاكُمْ وَلَعَلَّكُمْ تَشْكُرُونَ",
                                    style: AppTextStyles.madReg16(context, color: textClr),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 10.h),
                                  Text("سورة البقرة — ١٨٥",
                                      style: AppTextStyles.madReg12(context, color: mutedClr),
                                      textAlign: TextAlign.center),
                                ]),
                              ),
                            ),

                            SizedBox(height: 14.h),

                            // ── EID DAYS ──────────────────────────────
                            _SectionCard(
                              label: "أيام العيد",
                              primaryClr: primaryClr, textClr: textClr,
                              mutedClr: mutedClr, cardBg: cardBg, cardBorder: cardBorder,
                              child: Padding(
                                padding: EdgeInsets.all(14.w),
                                child: _DaysGrid(
                                  primaryClr: primaryClr, textClr: textClr,
                                  mutedClr: mutedClr, cardBorder: cardBorder,
                                ),
                              ),
                            ),

                            SizedBox(height: 14.h),

                            // ── SUNNAH ────────────────────────────────
                            _SectionCard(
                              label: "سنن العيد",
                              primaryClr: primaryClr, textClr: textClr,
                              mutedClr: mutedClr, cardBg: cardBg, cardBorder: cardBorder,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                child: Column(children: [
                                  _SunnahItem(number: "١", text: "الاغتسال والتطيب والتزيُّن قبل صلاة العيد",  primaryClr: primaryClr, textClr: textClr),
                                  _SunnahItem(number: "٢", text: "أكل التمر وتراً قبل الخروج إلى الصلاة",     primaryClr: primaryClr, textClr: textClr),
                                  _SunnahItem(number: "٣", text: "التكبير جهراً في الطريق إلى المصلى",         primaryClr: primaryClr, textClr: textClr),
                                  _SunnahItem(number: "٤", text: "الذهاب من طريق والعودة من طريق آخر",        primaryClr: primaryClr, textClr: textClr),
                                  _SunnahItem(number: "٥", text: "صلة الأرحام وتبادل التهاني والزيارات",       primaryClr: primaryClr, textClr: textClr),
                                  _SunnahItem(number: "٦", text: "إخراج زكاة الفطر قبل صلاة العيد",          primaryClr: primaryClr, textClr: textClr, isLast: true),
                                ]),
                              ),
                            ),

                            SizedBox(height: 14.h),

                            // ── DUA ───────────────────────────────────
                            _SectionCard(
                              label: "دعاء العيد",
                              primaryClr: primaryClr, textClr: textClr,
                              mutedClr: mutedClr, cardBg: cardBg, cardBorder: cardBorder,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
                                child: Column(children: [
                                  Text("تَقَبَّلَ اللهُ مِنَّا وَمِنكُم",
                                      style: AppTextStyles.madB20(context, color: primaryClr),
                                      textAlign: TextAlign.center),
                                  SizedBox(height: 10.h),
                                  Text(
                                    "اللَّهُمَّ تَقَبَّلْ مِنَّا صِيَامَنَا وَقِيَامَنَا\nوَاجْعَلْنَا مِنَ الْعُتَقَاءِ مِنَ النَّارِ",
                                    style: AppTextStyles.madReg16(context, color: textClr),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 14.h),
                                  _CopyDuaButton(primaryClr: primaryClr, textClr: textClr, cardBorder: cardBorder),
                                ]),
                              ),
                            ),

                            SizedBox(height: 14.h),

                            // ── TAKBEER ───────────────────────────────
                            _SectionCard(
                              label: "تكبيرات العيد",
                              primaryClr: primaryClr, textClr: textClr,
                              mutedClr: mutedClr, cardBg: cardBg, cardBorder: cardBorder,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
                                child: Column(children: [
                                  Text(
                                    "اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، اللهُ أَكْبَرُ\nلَا إِلَهَ إِلَّا اللهُ\nاللهُ أَكْبَرُ، اللهُ أَكْبَرُ\nوَلِلَّهِ الْحَمْدُ",
                                    style: AppTextStyles.madReg16(context, color: textClr),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 14.h),
                                  Text(
                                    "يُسنّ رفع الصوت بالتكبير من غروب شمس آخر يوم من رمضان حتى صلاة العيد",
                                    style: AppTextStyles.madReg12(context, color: mutedClr),
                                    textAlign: TextAlign.center,
                                  ),
                                ]),
                              ),
                            ),

                            SizedBox(height: 14.h),

                            // ── HADITH ────────────────────────────────
                            _SectionCard(
                              label: "حديث شريف",
                              primaryClr: primaryClr, textClr: textClr,
                              mutedClr: mutedClr, cardBg: cardBg, cardBorder: cardBorder,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
                                child: Column(children: [
                                  Align(
                                    alignment: AlignmentDirectional.topEnd,
                                    child: Text("❝",
                                        style: TextStyle(
                                            fontSize: 28.sp,
                                            color: primaryClr.withOpacity(0.35),
                                            height: 0.8)),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text("زيِّنوا أعيادكم بالتكبير",
                                      style: AppTextStyles.madB16(context, color: primaryClr),
                                      textAlign: TextAlign.center),
                                  SizedBox(height: 10.h),
                                  Text("عن ابن عباس رضي الله عنهما — رواه الطبراني",
                                      style: AppTextStyles.madReg12(context, color: mutedClr),
                                      textAlign: TextAlign.center),
                                ]),
                              ),
                            ),

                            SizedBox(height: 34.h),
                          ]),
                        ),
                      ),
                    ]),
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
  final Color textClr, cardBorder;

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
          border: Border.all(color: cardBorder),
        ),
        child: Text("تخطي", style: AppTextStyles.madReg14(context, color: textClr)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hero band
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBand extends StatelessWidget {
  const _HeroBand({
    required this.moonCtrl, required this.moonScale,
    required this.moonGlow, required this.shimmerCtrl,
  });
  final AnimationController moonCtrl, shimmerCtrl;
  final Animation<double> moonScale, moonGlow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 18.w),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), color: _heroBg),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _StarfieldPainter(_starDim))),
        Positioned(
          bottom: -70, left: -60, right: -60,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(200),
              color: const Color(AppColors.mainGreen).withOpacity(0.05),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0, height: 1.5,
          child: AnimatedBuilder(
            animation: shimmerCtrl,
            builder: (_, __) => ShaderMask(
              shaderCallback: (rect) {
                final dx = shimmerCtrl.value;
                return LinearGradient(
                  begin: Alignment(dx * 3 - 1.5, 0),
                  end:   Alignment(dx * 3 - 0.5, 0),
                  colors: [
                    _heroAccent.withOpacity(0.0),
                    _heroAccent.withOpacity(0.7),
                    _heroAccent.withOpacity(0.0),
                  ],
                ).createShader(rect);
              },
              child: Container(color: Colors.white),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 34.h, 24.w, 28.h),
          child: Column(children: [
            AnimatedBuilder(
              animation: moonCtrl,
              builder: (_, __) => Transform.scale(
                scale: moonScale.value,
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                    width: 88.w, height: 88.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                        color: _heroMoon.withOpacity(0.22 * moonGlow.value),
                        blurRadius: 44, spreadRadius: 22,
                      )],
                    ),
                  ),
                  CustomPaint(size: Size(70.w, 70.w), painter: _CrescentPainter(_heroMoon, _heroAccent)),
                ]),
              ),
            ),
            SizedBox(height: 18.h),
            Text("عيد الفطر المبارك",
                style: AppTextStyles.madB24(context, color: Colors.white),
                textAlign: TextAlign.center),
            SizedBox(height: 5.h),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 32.w, height: 0.5, color: _heroAccent.withOpacity(0.45)),
              SizedBox(width: 10.w),
              Text("١٤٤٧ هـ",
                  style: AppTextStyles.madReg14(context, color: _heroAccent.withOpacity(0.85))),
              SizedBox(width: 10.w),
              Container(width: 32.w, height: 0.5, color: _heroAccent.withOpacity(0.45)),
            ]),
            SizedBox(height: 20.h),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _HeroChip(label: "٢٠ مارس", sub: "بداية العيد"),
              SizedBox(width: 8.w),
              Text("—", style: TextStyle(color: _heroAccent.withOpacity(0.4), fontSize: 16.sp)),
              SizedBox(width: 8.w),
              _HeroChip(label: "٢٣ مارس", sub: "نهاية العيد"),
            ]),
            SizedBox(height: 8.h),
            Text(
              "تَقَبَّلَ اللهُ مِنَّا وَمِنكُم صَالِحَ الأَعمَال",
              style: AppTextStyles.madReg12(context, color: _heroSub.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ]),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.sub});
  final String label, sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.07),
        border: Border.all(color: Colors.white.withOpacity(0.11)),
      ),
      child: Column(children: [
        Text(label, style: AppTextStyles.madB14(context, color: Colors.white)),
        SizedBox(height: 2.h),
        Text(sub, style: AppTextStyles.madReg10(context, color: _heroSub)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Countdown banner  — reads fresh DateTime.now() each build, driven by Timer
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownBanner extends StatelessWidget {
  const _CountdownBanner({
    required this.countdown,
    required this.primaryClr, required this.textClr,
    required this.mutedClr,   required this.cardBg,
    required this.cardBorder,
  });
  final (int, int, int, int) countdown;
  final Color primaryClr, textClr, mutedClr, cardBg, cardBorder;

  @override
  Widget build(BuildContext context) {
    final (d, h, m, s) = countdown;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardBg,
        border: Border.all(color: cardBorder),
      ),
      child: Column(children: [
        Row(children: [
          Icon(Icons.hourglass_top_rounded, color: primaryClr, size: 16.sp),
          SizedBox(width: 6.w),
          Text("العد التنازلي لعيد الفطر",
              style: AppTextStyles.madReg12(context, color: mutedClr)),
        ]),
        SizedBox(height: 14.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CountUnit(value: d.toString().padLeft(2, '0'), label: "يوم",   primaryClr: primaryClr, textClr: textClr, mutedClr: mutedClr, cardBorder: cardBorder),
            _Colon(primaryClr: primaryClr),
            _CountUnit(value: h.toString().padLeft(2, '0'), label: "ساعة",  primaryClr: primaryClr, textClr: textClr, mutedClr: mutedClr, cardBorder: cardBorder),
            _Colon(primaryClr: primaryClr),
            _CountUnit(value: m.toString().padLeft(2, '0'), label: "دقيقة", primaryClr: primaryClr, textClr: textClr, mutedClr: mutedClr, cardBorder: cardBorder),
            _Colon(primaryClr: primaryClr),
            _CountUnit(value: s.toString().padLeft(2, '0'), label: "ثانية", primaryClr: primaryClr, textClr: textClr, mutedClr: mutedClr, cardBorder: cardBorder),
          ],
        ),
      ]),
    );
  }
}

class _CountUnit extends StatelessWidget {
  const _CountUnit({
    required this.value, required this.label,
    required this.primaryClr, required this.textClr,
    required this.mutedClr,   required this.cardBorder,
  });
  final String value, label;
  final Color primaryClr, textClr, mutedClr, cardBorder;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 54.w,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: primaryClr.withOpacity(0.08),
          border: Border.all(color: primaryClr.withOpacity(0.2)),
        ),
        child: Text(value,
            textAlign: TextAlign.center,
            style: AppTextStyles.madB20(context, color: primaryClr)),
      ),
      SizedBox(height: 5.h),
      Text(label, style: AppTextStyles.madReg10(context, color: mutedClr)),
    ]);
  }
}

class _Colon extends StatelessWidget {
  const _Colon({required this.primaryClr});
  final Color primaryClr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Text(":", style: TextStyle(
          color: primaryClr, fontSize: 22.sp, fontWeight: FontWeight.bold)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Status banner
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.isNow,
    required this.primaryClr, required this.textClr,
    required this.mutedClr,   required this.cardBg,
    required this.cardBorder,
  });
  final bool isNow;
  final Color primaryClr, textClr, mutedClr, cardBg, cardBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isNow ? primaryClr.withOpacity(0.10) : cardBg,
        border: Border.all(
            color: isNow ? primaryClr.withOpacity(0.5) : cardBorder,
            width: isNow ? 1.5 : 1),
      ),
      child: Row(children: [
        Container(
          width: 38.w, height: 38.w,
          decoration: BoxDecoration(shape: BoxShape.circle, color: primaryClr.withOpacity(0.12)),
          child: Icon(
            isNow ? Icons.celebration_rounded : Icons.auto_awesome_rounded,
            color: primaryClr, size: 18.sp,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isNow ? "نحن الآن في أيام العيد" : "انتهى العيد",
              style: AppTextStyles.madReg12(context, color: mutedClr)),
          SizedBox(height: 2.h),
          Text(
            isNow ? "عيد مبارك سعيد! كل عام وأنتم بخير" : "إلى العام القادم بإذن الله ✨",
            style: AppTextStyles.madB16(context, color: textClr),
          ),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Greeting card
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingCard extends StatefulWidget {
  const _GreetingCard({
    required this.primaryClr, required this.textClr,
    required this.mutedClr,   required this.cardBg,
    required this.cardBorder,
  });
  final Color primaryClr, textClr, mutedClr, cardBg, cardBorder;

  @override
  State<_GreetingCard> createState() => _GreetingCardState();
}

class _GreetingCardState extends State<_GreetingCard> {
  int _selected = 0;

  static const _greetings = [
    "عيد مبارك وكل عام وأنتم بخير، تقبّل الله منا ومنكم صالح الأعمال 🌙",
    "أعاده الله عليكم بالخير واليمن والبركات، وجعلنا وإياكم من عتقائه من النار 🤲",
    "تقبَّل الله صيامكم وقيامكم، وجعل هذا العيد بداية أيامٍ مباركة بإذن الله ✨",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: widget.cardBg,
        border: Border.all(color: widget.cardBorder),
      ),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            color: widget.primaryClr.withOpacity(0.07),
            border: Border(bottom: BorderSide(color: widget.cardBorder)),
          ),
          child: Row(children: [
            Container(width: 3.w, height: 14.h,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2), color: widget.primaryClr)),
            SizedBox(width: 10.w),
            Text("رسائل التهنئة",
                style: AppTextStyles.madReg12(context, color: widget.primaryClr)),
            const Spacer(),
            Text("${_selected + 1} / ${_greetings.length}",
                style: AppTextStyles.madReg10(context, color: widget.mutedClr)),
          ]),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 14.h),
          child: Text(_greetings[_selected],
              style: AppTextStyles.madReg16(context, color: widget.textClr),
              textAlign: TextAlign.center),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
          child: Row(children: [
            Row(children: List.generate(_greetings.length, (i) => GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(left: 4.w),
                width: _selected == i ? 18.w : 6.w,
                height: 6.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: _selected == i
                      ? widget.primaryClr
                      : widget.primaryClr.withOpacity(0.2),
                ),
              ),
            ))),
            const Spacer(),
            _SmallButton(
              label: "نسخ", icon: Icons.copy_rounded,
              primaryClr: widget.primaryClr, textClr: widget.textClr, cardBorder: widget.cardBorder,
              onTap: () {
                Clipboard.setData(ClipboardData(text: _greetings[_selected]));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("تم نسخ التهنئة",
                      style: AppTextStyles.madReg14(context, color: Colors.white)),
                  backgroundColor: widget.primaryClr,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ));
              },
            ),
            SizedBox(width: 8.w),
            _SmallButton(
              label: "التالي", icon: Icons.arrow_back_ios_rounded,
              primaryClr: widget.primaryClr, textClr: widget.textClr, cardBorder: widget.cardBorder,
              onTap: () => setState(() => _selected = (_selected + 1) % _greetings.length),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label, required this.icon,
    required this.primaryClr, required this.textClr, required this.cardBorder,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color primaryClr, textClr, cardBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder),
        ),
        child: Row(children: [
          Icon(icon, size: 12.sp, color: primaryClr),
          SizedBox(width: 4.w),
          Text(label, style: AppTextStyles.madReg12(context, color: textClr)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable section card shell
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.label,
    required this.primaryClr, required this.textClr,
    required this.mutedClr,   required this.cardBg,
    required this.cardBorder, required this.child,
  });
  final String label;
  final Color primaryClr, textClr, mutedClr, cardBg, cardBorder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardBg,
        border: Border.all(color: cardBorder),
      ),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            color: primaryClr.withOpacity(0.07),
            border: Border(bottom: BorderSide(color: cardBorder)),
          ),
          child: Row(children: [
            Container(width: 3.w, height: 14.h,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2), color: primaryClr)),
            SizedBox(width: 10.w),
            Text(label, style: AppTextStyles.madReg12(context, color: primaryClr)),
          ]),
        ),
        child,
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sunnah item
// ─────────────────────────────────────────────────────────────────────────────

class _SunnahItem extends StatelessWidget {
  const _SunnahItem({
    required this.number, required this.text,
    required this.primaryClr, required this.textClr,
    this.isLast = false,
  });
  final String number, text;
  final Color primaryClr, textClr;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 26.w, height: 26.w,
          decoration: BoxDecoration(shape: BoxShape.circle, color: primaryClr.withOpacity(0.1)),
          child: Center(child: Text(number,
              style: AppTextStyles.madB12(context, color: primaryClr))),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 3.h),
            child: Text(text, style: AppTextStyles.madReg14(context, color: textClr)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Copy dua button
// ─────────────────────────────────────────────────────────────────────────────

class _CopyDuaButton extends StatelessWidget {
  const _CopyDuaButton({
    required this.primaryClr, required this.textClr, required this.cardBorder,
  });
  final Color primaryClr, textClr, cardBorder;

  static const _dua =
      "اللَّهُمَّ تَقَبَّلْ مِنَّا صِيَامَنَا وَقِيَامَنَا\nوَاجْعَلْنَا مِنَ الْعُتَقَاءِ مِنَ النَّارِ";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(const ClipboardData(text: _dua));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("تم نسخ الدعاء",
              style: AppTextStyles.madReg14(context, color: Colors.white)),
          backgroundColor: primaryClr,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryClr.withOpacity(0.35)),
          color: primaryClr.withOpacity(0.07),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.copy_rounded, size: 14.sp, color: primaryClr),
          SizedBox(width: 6.w),
          Text("نسخ الدعاء", style: AppTextStyles.madReg12(context, color: primaryClr)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Days grid
// ─────────────────────────────────────────────────────────────────────────────

class _DaysGrid extends StatelessWidget {
  const _DaysGrid({
    required this.primaryClr, required this.textClr,
    required this.mutedClr,   required this.cardBorder,
  });
  final Color primaryClr, textClr, mutedClr, cardBorder;

  static const _days = [
    {"ar": "١", "greg": "٢٠ مارس", "hijri": "١ شوال", "label": "يوم العيد الأول",  "m": 3, "d": 20},
    {"ar": "٢", "greg": "٢١ مارس", "hijri": "٢ شوال", "label": "يوم العيد الثاني", "m": 3, "d": 21},
    {"ar": "٣", "greg": "٢٢ مارس", "hijri": "٣ شوال", "label": "يوم العيد الثالث", "m": 3, "d": 22},
    {"ar": "٤", "greg": "٢٣ مارس", "hijri": "٤ شوال", "label": "يوم العيد الرابع",  "m": 3, "d": 23},
  ];

  bool _isToday(int m, int d) {
    final n = DateTime.now();
    return n.year == 2026 && n.month == m && n.day == d;
  }

  bool _isPast(int m, int d) {
    final n = DateTime.now();
    return n.isAfter(DateTime(2026, m, d, 23, 59, 59));
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
        childAspectRatio: 1.4,
      ),
      itemBuilder: (_, i) {
        final item  = _days[i];
        final today = _isToday(item["m"] as int, item["d"] as int);
        final past  = _isPast(item["m"] as int, item["d"] as int);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: today
                ? primaryClr.withOpacity(0.13)
                : past
                ? primaryClr.withOpacity(0.03)
                : primaryClr.withOpacity(0.06),
            border: Border.all(
              color: today ? primaryClr : primaryClr.withOpacity(past ? 0.1 : 0.15),
              width: today ? 1.8 : 1,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 24.w, height: 24.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: today
                      ? primaryClr
                      : past
                      ? primaryClr.withOpacity(0.08)
                      : primaryClr.withOpacity(0.12),
                ),
                child: Center(
                  child: past && !today
                      ? Icon(Icons.check, size: 12.sp, color: primaryClr.withOpacity(0.5))
                      : Text(item["ar"] as String,
                      style: AppTextStyles.madB12(context,
                          color: today ? Colors.white : primaryClr.withOpacity(past ? 0.4 : 1))),
                ),
              ),
              if (today) ...[
                SizedBox(width: 5.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(color: primaryClr, borderRadius: BorderRadius.circular(20)),
                  child: Text("اليوم", style: AppTextStyles.madReg10(context, color: Colors.white)),
                ),
              ],
            ]),
            SizedBox(height: 7.h),
            Text(item["greg"] as String,
                style: AppTextStyles.madB14(context,
                    color: today ? primaryClr : textClr.withOpacity(past ? 0.4 : 1))),
            SizedBox(height: 2.h),
            Text(item["hijri"] as String,
                style: AppTextStyles.madReg10(context, color: mutedClr.withOpacity(past ? 0.5 : 1))),
            SizedBox(height: 2.h),
            Text(item["label"] as String,
                style: AppTextStyles.madReg11(context,
                    color: textClr.withOpacity(past ? 0.35 : 0.65)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Painters
// ─────────────────────────────────────────────────────────────────────────────

class _CrescentPainter extends CustomPainter {
  const _CrescentPainter(this.fillColor, this.rimColor);
  final Color fillColor, rimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.46;
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = fillColor);
    canvas.drawCircle(Offset(cx - r * 0.30, cy - r * 0.10), r * 0.82, Paint()..color = _heroBg);
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = rimColor.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(_CrescentPainter old) => false;
}

class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter(this.color);
  final Color color;

  static final _stars = List.generate(44, (i) {
    final r = Random(i * 997 + 3);
    return (x: r.nextDouble(), y: r.nextDouble() * 0.8,
    size: 0.5 + r.nextDouble() * 1.6, opacity: 0.12 + r.nextDouble() * 0.5);
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height),
          s.size, Paint()..color = color.withOpacity(s.opacity));
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => false;
}

class _LanternPainter extends CustomPainter {
  _LanternPainter(this.progress, this.color);
  final double progress;
  final Color color;

  static final _specs = List.generate(16, (i) {
    final r = Random(i * 137 + 41);
    return (x: r.nextDouble(), phase: r.nextDouble(),
    speed: 0.005 + r.nextDouble() * 0.011,
    size: 2.0 + r.nextDouble() * 4.5,
    swing: 8.0 + r.nextDouble() * 14,
    opacity: 0.05 + r.nextDouble() * 0.10);
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _specs) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final y = size.height * (1.0 - t);
      final x = size.width * p.x + sin(t * 2 * pi * 1.4 + p.phase * 10) * p.swing;
      if (y < -20) continue;
      canvas.drawCircle(Offset(x, y), p.size,
          Paint()
            ..color = color.withOpacity(p.opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
  }

  @override
  bool shouldRepaint(_LanternPainter old) => old.progress != progress;
}