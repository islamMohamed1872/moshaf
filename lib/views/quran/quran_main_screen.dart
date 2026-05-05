import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/quran_audio/audio_quran_cubit.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';
import 'package:moshaf/controllers/text_quran/text_quran_cubit.dart';
import 'package:moshaf/controllers/text_quran/text_quran_states.dart';
import 'package:moshaf/views/quran/all_quran_screen.dart';
import 'package:moshaf/views/quran/audio_screen.dart';
import 'package:moshaf/views/quran/tafseer_search_screen.dart';
import 'package:moshaf/views/quran/widgets/quran_page.dart';
import 'package:moshaf/views/widgets/header.dart';
import 'package:quran/quran.dart' as quran;

import '../search/search_screen.dart';

class QuranMainScreen extends StatelessWidget {
  const QuranMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit c) => c.isDark);
    final gold   = AppColors.isGoldMode;

    final bgClr = gold
        ? const Color(AppColors.goldBackground)
        : (isDark ? const Color(AppColors.scaffoldBg) : Colors.white);

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final accentClr = gold
        ? const Color(AppColors.goldPrimary)
        : Color(AppColors.mainGreen);

    final subtitleClr = gold
        ? const Color(AppColors.goldText).withValues(alpha: 0.6)
        : (isDark ? Colors.white54 : Colors.black45);

    return BlocBuilder<TextQuranCubit, TextQuranStates>(
      builder: (context, state) {
        final cubit = TextQuranCubit.get(context);

        return Scaffold(
          backgroundColor: bgClr,
          body: SafeArea(
            child: Column(
              children: [

                // ── Hero header ────────────────────────────────
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      "assets/images/sorah_bg.png",
                      height: 220.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      width: double.infinity,
                      height: 220.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0),
                            bgClr,
                          ],
                        ),
                      ),
                    ),

                    // Back button + title
                    Positioned(
                      top: 15, right: 0, left: 0,
                      child: Header(
                        title: "القرآن الكريم",
                        onTap: () => Navigator.pop(context),
                        isDark: isDark,
                        iconColor: gold ? const Color(AppColors.goldAccent) : null,
                      ),
                    ),

                    // Centre verse preview — taps to resume last read
                    Positioned(
                      right: 16, left: 16,
                      child: GestureDetector(
                        onTap: () => _resumeReading(context, cubit),
                        child: Text(
                          cubit.savedVerseContent.isNotEmpty
                              ? cubit.savedVerseContent
                              : "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.arsura24(
                            context,
                            color: gold
                                ? const Color(AppColors.goldAccent)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // "Resume reading" hint
                    if (cubit.savedSora > 0)
                      Positioned(
                        bottom: 6,
                        child: GestureDetector(
                          onTap: () => _resumeReading(context, cubit),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: accentClr),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bookmark_rounded,
                                    size: 13.sp, color: accentClr),
                                SizedBox(width: 5.w),
                                Text(
                                  "متابعة القراءة · ${quran.getSurahNameArabic(cubit.savedSora)}",
                                  style: AppTextStyles.madMd12(
                                      context, color: accentClr),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // ── Divider ────────────────────────────────────
                Container(
                  height: 1,
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 20.h),
                  color: borderClr,
                ),

                // ── Three main action cards ────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [

                        // ── Row 1: Read + Listen ──────────────
                        Row(
                          children: [
                            Expanded(
                              child: _ActionCard(
                                icon: FontAwesomeIcons.bookQuran,
                                label: "قراءة",
                                subtitle: "تصفح المصحف",
                                accentClr: accentClr,
                                borderClr: borderClr,
                                textClr: textClr,
                                subtitleClr: subtitleClr,
                                bgClr: bgClr,
                                onTap: () => navigateTo(
                                  context,
                                  const AllQuranScreen(),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _ActionCard(
                                icon: FontAwesomeIcons.headphones,
                                label: "استماع",
                                subtitle: "تلاوة وترتيل",
                                accentClr: accentClr,
                                borderClr: borderClr,
                                textClr: textClr,
                                subtitleClr: subtitleClr,
                                bgClr: bgClr,
                                onTap: (){
                                  AudioQuranCubit.get(context).sorahNumber = 1;
                                  cubit.soraNumber = 1;
                                  navigateTo(
                                    context,
                                    AudioScreen(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10.h),

                        // ── Row 2: Tafseer + Search ────────────
                        Row(
                          children: [
                            Expanded(
                              child: _ActionCard(
                                icon: FontAwesomeIcons.lightbulb,
                                label: "التفسير",
                                subtitle: "تفسير الآيات",
                                accentClr: accentClr,
                                borderClr: borderClr,
                                textClr: textClr,
                                subtitleClr: subtitleClr,
                                bgClr: bgClr,
                                onTap: () => navigateTo(
                                  context,
                                  const TafseerSearchScreen(),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.search_rounded,
                                label: "بحث",
                                subtitle: "ابحث في القرآن",
                                accentClr: accentClr,
                                borderClr: borderClr,
                                textClr: textClr,
                                subtitleClr: subtitleClr,
                                bgClr: bgClr,
                                onTap: () => navigateTo(
                                  context,
                                  const SearchScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24.h),

                        // ── Stats strip ───────────────────────
                        _StatsStrip(
                          accentClr: accentClr,
                          borderClr: borderClr,
                          textClr: textClr,
                          subtitleClr: subtitleClr,
                        ),

                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resumeReading(BuildContext context, TextQuranCubit cubit) {
    if (cubit.savedSora <= 0) return;
    navigateTo(
      context,
      QuranViewPage(
        navigatedFromRecitation: false,
        shouldHighlightText: true,
        highlightVerse: cubit.savedVerse.toString(),
        jsonData: cubit.suraJsonData,
        pageNumber: quran.getPageNumber(cubit.savedSora, cubit.savedVerse),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// Action card widget
// ════════════════════════════════════════════════════

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentClr;
  final Color borderClr;
  final Color textClr;
  final Color subtitleClr;
  final Color bgClr;
  final VoidCallback onTap;
  final bool isWide;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentClr,
    required this.borderClr,
    required this.textClr,
    required this.subtitleClr,
    required this.bgClr,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isWide ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 20.w : 16.w,
          vertical: isWide ? 18.h : 22.h,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderClr),
          color: accentClr.withValues(alpha: 0.04),
        ),
        child: isWide
            ? Row(
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentClr.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: accentClr, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.madB16(context, color: textClr)),
                SizedBox(height: 2.h),
                Text(subtitle,
                    style: AppTextStyles.madReg12(
                        context, color: subtitleClr)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_back_ios_rounded,
                color: accentClr, size: 16.sp),
          ],
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentClr.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: accentClr, size: 22.sp),
            ),
            SizedBox(height: 10.h),
            Text(label,
                style: AppTextStyles.madB16(context, color: textClr)),
            SizedBox(height: 3.h),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.madReg12(
                    context, color: subtitleClr)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// Stats strip — 114 سورة · 30 جزء · 6236 آية
// ════════════════════════════════════════════════════

class _StatsStrip extends StatelessWidget {
  final Color accentClr;
  final Color borderClr;
  final Color textClr;
  final Color subtitleClr;

  const _StatsStrip({
    required this.accentClr,
    required this.borderClr,
    required this.textClr,
    required this.subtitleClr,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      ("114", "سورة"),
      ("30", "جزءًا"),
      ("6236", "آية"),
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderClr),
      ),
      child: Row(
        children: stats.asMap().entries.map((entry) {
          final i    = entry.key;
          final stat = entry.value;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(stat.$1,
                          style: AppTextStyles.madB20(context, color: accentClr)),
                      SizedBox(height: 2.h),
                      Text(stat.$2,
                          style: AppTextStyles.madReg12(
                              context, color: subtitleClr)),
                    ],
                  ),
                ),
                if (i < stats.length - 1)
                  Container(width: 1, height: 30.h, color: borderClr),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}