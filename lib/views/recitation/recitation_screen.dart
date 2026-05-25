import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/recitation/recitation_cubit.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';
import 'package:moshaf/views/widgets/header.dart';
import 'package:quran/quran.dart' as quran;

import '../../controllers/recitation/recitation_state.dart';
import '../quran/widgets/quran_page.dart';

class RecitationScreen extends StatelessWidget {
  const RecitationScreen({super.key});

  @override
  Widget build(BuildContext context) => const _RecitationView();
}

class _RecitationView extends StatelessWidget {
  const _RecitationView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit c) => c.isDark);
    final gold = AppColors.isGoldMode;

    return Scaffold(
      body: BlocBuilder<RecitationCubit, RecitationStates>(
        builder: (context, state) {
          final cubit = RecitationCubit.get(context);

          if (state is RecitationLoadingState) {
            return Center(
              child: CircularProgressIndicator(
                color: gold
                    ? const Color(AppColors.goldPrimary)
                    : Color(AppColors.mainGreen),
              ),
            );
          }

          return cubit.hasActiveGoal
              ? _ActiveGoalView(cubit: cubit, isDark: isDark, gold: gold)
              : _StartGoalView(cubit: cubit, isDark: isDark, gold: gold);
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// START GOAL VIEW  (unchanged visually, minor refactor)
// ══════════════════════════════════════════════════
class _StartGoalView extends StatelessWidget {
  final RecitationCubit cubit;
  final bool isDark;
  final bool gold;

  const _StartGoalView({
    required this.cubit,
    required this.isDark,
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    final accentClr =
    gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen);

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final subtitleClr = gold
        ? const Color(AppColors.goldText).withOpacity(0.7)
        : (isDark ? Colors.white70 : Colors.black54);

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 40.h),
          Header(
            title: 'الوِرد اليومي',
            isDark: isDark,
            iconColor: gold
                ? textClr
                : isDark
                ? Colors.white
                : Colors.black,
          ),
          SizedBox(height: 20.h),

          _RafeqBanner(
            imagePath: 'assets/images/rafeq_reminder.png',
            message: 'لم تحدد وردك اليومي بعد!\nابدأ رحلتك مع القرآن الآن',
            gold: gold,
            isDark: isDark,
            accentColor: accentClr,
          ),

          SizedBox(height: 30.h),

          Text(
            'ابدأ رحلتك مع القرآن',
            style: AppTextStyles.madB24(context, color: textClr),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            'حدد عدد الصفحات التي تريد قراءتها يومياً\nوسنساعدك على إكمال القرآن الكريم',
            style: AppTextStyles.madReg14(context, color: subtitleClr),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40.h),

          // ── Pages selector ──
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: borderClr),
            ),
            child: Column(
              children: [
                Text(
                  'عدد الصفحات اليومية',
                  style: AppTextStyles.madB16(context, color: textClr),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (cubit.dailyPagesTarget > 1) {
                          cubit.dailyPagesTarget--;
                          cubit.emit(RecitationUpdateUIState());
                        }
                      },
                      onLongPressStart: (_) =>
                          cubit.startAutoChange(isIncrement: false),
                      onLongPressEnd: (_) => cubit.stopAutoChange(),
                      child: Icon(Icons.remove_circle_outline,
                          color: textClr, size: 32.w),
                    ),
                    SizedBox(width: 20.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 30.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: accentClr,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${cubit.dailyPagesTarget}',
                        style: AppTextStyles.madB32(context,
                            color: Colors.white),
                      ),
                    ),
                    SizedBox(width: 20.w),
                    GestureDetector(
                      onTap: () {
                        if (cubit.dailyPagesTarget < 302) {
                          cubit.dailyPagesTarget++;
                          cubit.emit(RecitationUpdateUIState());
                        }
                      },
                      onLongPressStart: (_) =>
                          cubit.startAutoChange(isIncrement: true),
                      onLongPressEnd: (_) => cubit.stopAutoChange(),
                      child: Icon(Icons.add_circle_outline,
                          color: textClr, size: 32.w),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  'ستنتهي من القرآن في ${(604 / cubit.dailyPagesTarget).ceil()} يوم',
                  style: AppTextStyles.madReg14(context, color: subtitleClr),
                ),
              ],
            ),
          ),

          SizedBox(height: 40.h),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async => cubit.startNewGoal(cubit.dailyPagesTarget),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentClr,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'ابدأ الآن',
                style: AppTextStyles.madB16(context, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// ACTIVE GOAL VIEW  (redesigned)
// ══════════════════════════════════════════════════
class _ActiveGoalView extends StatelessWidget {
  final RecitationCubit cubit;
  final bool isDark;
  final bool gold;

  const _ActiveGoalView({
    required this.cubit,
    required this.isDark,
    required this.gold,
  });

  Color get accentClr =>
      gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen);

  Color get borderClr => gold
      ? const Color(AppColors.goldBorder)
      : Color(isDark
      ? AppColors.containerDarkBorders
      : AppColors.containerLightBorders);

  Color get textClr => gold
      ? const Color(AppColors.goldText)
      : (isDark ? Colors.white : Colors.black);

  Color get subtitleClr => gold
      ? const Color(AppColors.goldText).withOpacity(0.7)
      : (isDark ? Colors.white70 : Colors.black54);

  Color get surfaceClr =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8F8);

  @override
  Widget build(BuildContext context) {
    final dailyRange = cubit.getDailyReadingRange();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Header(
              title: 'الوِرد اليومي',
              isDark: isDark,
              iconColor: gold
                  ? textClr
                  : isDark
                  ? Colors.white
                  : Colors.black,
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ── 1. Rafeq Banner ──
                    _RafeqBanner(
                      imagePath: cubit.rafeqImageAsset,
                      message: cubit.rafeqMessage,
                      gold: gold,
                      isDark: isDark,
                      accentColor: cubit.isTodayCompleted
                          ? Colors.green
                          : accentClr,
                      showBadge: cubit.isTodayCompleted,
                    ),

                    SizedBox(height: 20.h),

                    // ── 2. TODAY'S PROGRESS (Hero card) ──
                    _TodayProgressCard(
                      cubit: cubit,
                      gold: gold,
                      isDark: isDark,
                      accentClr: accentClr,
                      borderClr: borderClr,
                      textClr: textClr,
                      subtitleClr: subtitleClr,
                    ),

                    SizedBox(height: 16.h),

                    // ── 3. Today's Reading Range ──
                    _ReadingRangeCard(
                      cubit: cubit,
                      dailyRange: dailyRange,
                      gold: gold,
                      isDark: isDark,
                      accentClr: accentClr,
                      borderClr: borderClr,
                      textClr: textClr,
                      subtitleClr: subtitleClr,
                      context: context,
                    ),

                    SizedBox(height: 16.h),

                    // ── 4. Overall Progress (compact) ──
                    _OverallProgressCard(
                      cubit: cubit,
                      gold: gold,
                      isDark: isDark,
                      accentClr: accentClr,
                      textClr: textClr,
                      borderClr: borderClr,
                      subtitleClr: subtitleClr,
                      context: context,
                    ),

                    SizedBox(height: 16.h),

                    // ── 5. Reset ──
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async =>
                            _showResetDialog(context, cubit, isDark, gold),
                        child: Text(
                          'إعادة تعيين الهدف',
                          style: AppTextStyles.madReg14(context,
                              color: Colors.red),
                        ),
                      ),
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
  }

  Future<void> _showResetDialog(
      BuildContext context,
      RecitationCubit cubit,
      bool isDark,
      bool gold,
      ) async {
    final bgColor = gold
        ? const Color(AppColors.goldBackground)
        : (isDark ? const Color(0xFF151515) : Colors.white);

    final textColor = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final bdrClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: bdrClr),
        ),
        titlePadding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
        contentPadding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 10.h),
        actionsPadding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 10.h),
        title: Text(
          'إعادة تعيين الهدف',
          textAlign: TextAlign.center,
          style: AppTextStyles.madB18(context, color: textColor),
        ),
        content: Text(
          'هل أنت متأكد؟ سيتم حذف كل التقدم الحالي.',
          textAlign: TextAlign.center,
          style: AppTextStyles.madReg14(context,
              color: textColor.withOpacity(.8)),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding:
              EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'إلغاء',
              style: AppTextStyles.madReg14(context,
                  color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await cubit.resetGoal();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
              gold ? const Color(AppColors.goldPrimary) : Colors.red,
              padding:
              EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'تأكيد',
              style: AppTextStyles.madB14(context, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// TODAY'S PROGRESS CARD
// Circular ring + pages read today + mark buttons
// ══════════════════════════════════════════════════
class _TodayProgressCard extends StatelessWidget {
  final RecitationCubit cubit;
  final bool gold;
  final bool isDark;
  final Color accentClr;
  final Color borderClr;
  final Color textClr;
  final Color subtitleClr;

  const _TodayProgressCard({
    required this.cubit,
    required this.gold,
    required this.isDark,
    required this.accentClr,
    required this.borderClr,
    required this.textClr,
    required this.subtitleClr,
  });

  @override
  Widget build(BuildContext context) {
    final progressValue =
    (cubit.todayPagesRead / cubit.dailyPagesTarget).clamp(0.0, 1.0);
    final isOver = cubit.isOverAchieved;
    final ringColor = isOver ? Colors.amber : accentClr;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderClr),
      ),
      child: Column(
        children: [
          // ── Title row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إنجاز اليوم',
                style: AppTextStyles.madB18(context, color: textClr),
              ),
              if (isOver)
                Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 13),
                      SizedBox(width: 4.w),
                      Text(
                        '+${cubit.extraPagesReadToday} إضافية',
                        style: AppTextStyles.madReg10(context,
                            color: Colors.amber),
                      ),
                    ],
                  ),
                )
              else if (cubit.isTodayCompleted)
                Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 13),
                      SizedBox(width: 4.w),
                      Text(
                        'أتممت اليوم',
                        style: AppTextStyles.madReg10(context,
                            color: Colors.green),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          SizedBox(height: 20.h),

          // ── Circular progress + buttons row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ring indicator
              SizedBox(
                width: 90.w,
                height: 90.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background track
                    SizedBox(
                      width: 90.w,
                      height: 90.w,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        color: borderClr,
                      ),
                    ),
                    // Progress arc
                    SizedBox(
                      width: 90.w,
                      height: 90.w,
                      child: CircularProgressIndicator(
                        value: progressValue,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    // Center text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${cubit.todayPagesRead}',
                          style: AppTextStyles.madB24(context, color: textClr),
                        ),
                        Text(
                          'من ${cubit.dailyPagesTarget}',
                          style: AppTextStyles.madReg10(context,
                              color: subtitleClr),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 20.w),

              // Status + mark buttons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cubit.isTodayCompleted
                          ? (isOver
                          ? 'تجاوزت هدفك! أحسنت 🌟'
                          : 'أتممت وردك اليوم! 🎉')
                          : 'تبقى لك ${cubit.todayPagesRemaining} صفحة اليوم',
                      style: AppTextStyles.madB14(context, color: textClr),
                    ),

                    SizedBox(height: 6.h),

                    Text(
                      cubit.isTodayCompleted
                          ? 'يمكنك الاستمرار للتفوق على هدفك'
                          : 'سجّل ما قرأته الآن',
                      style:
                      AppTextStyles.madReg12(context, color: subtitleClr),
                    ),

                    SizedBox(height: 14.h),

                    // ── Mark buttons ──
                    Row(
                      children: [
                        // +1 page
                        _MarkButton(
                          label: '+1',
                          color: accentClr,
                          isDark: isDark,
                          onTap: () async => cubit.markPagesRead(1),
                          context: context,
                        ),
                        SizedBox(width: 10.w),
                        // +daily target
                        _MarkButton(
                          label: '+${cubit.dailyPagesTarget}',
                          color: accentClr,
                          isDark: isDark,
                          onTap: () async =>
                              cubit.markPagesRead(cubit.dailyPagesTarget),
                          context: context,
                          filled: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small mark-pages button ──
class _MarkButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final BuildContext context;
  final bool filled;

  const _MarkButton({
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    required this.context,
    this.filled = false,
  });

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: filled ? null : Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: AppTextStyles.madB14(
            context,
            color: filled ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// TODAY'S READING RANGE CARD
// ══════════════════════════════════════════════════
class _ReadingRangeCard extends StatelessWidget {
  final RecitationCubit cubit;
  final Map<String, dynamic> dailyRange;
  final bool gold;
  final bool isDark;
  final Color accentClr;
  final Color borderClr;
  final Color textClr;
  final Color subtitleClr;
  final BuildContext context;

  const _ReadingRangeCard({
    required this.cubit,
    required this.dailyRange,
    required this.gold,
    required this.isDark,
    required this.accentClr,
    required this.borderClr,
    required this.textClr,
    required this.subtitleClr,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'قراءة اليوم',
            style: AppTextStyles.madB18(ctx, color: textClr),
          ),
          SizedBox(height: 16.h),

          // From page
          _RangeRow(
            label: 'من الصفحة',
            page: '${dailyRange['startPage']}',
            surahLine: dailyRange['startInfo'] != null
                ? 'سورة ${dailyRange['startInfo']['startSurahName']} — آية ${dailyRange['startInfo']['startVerse']}'
                : null,
            accentClr: accentClr,
            subtitleClr: subtitleClr,
            ctx: ctx,
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Divider(height: 1, color: borderClr),
          ),

          // To page
          _RangeRow(
            label: 'إلى الصفحة',
            page: '${dailyRange['endPage']}',
            surahLine: dailyRange['endInfo'] != null
                ? 'سورة ${dailyRange['endInfo']['endSurahName']} — آية ${dailyRange['endInfo']['endVerse']}'
                : null,
            accentClr: accentClr,
            subtitleClr: subtitleClr,
            ctx: ctx,
          ),

          SizedBox(height: 16.h),

          // Start reading button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                navigateTo(
                  ctx,
                  QuranViewPage(
                    navigatedFromRecitation: true,
                    shouldHighlightText: true,
                    highlightVerse:
                    dailyRange['startInfo']['startVerse'].toString(),
                    jsonData: cubit.suraJsonData,
                    pageNumber: quran.getPageNumber(
                      dailyRange['startInfo']['startSurahNumber'],
                      dailyRange['startInfo']['startVerse'],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book, size: 18),
              label: Text(
                'ابدأ القراءة',
                style: AppTextStyles.madReg14(ctx, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentClr,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 13.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  final String label;
  final String page;
  final String? surahLine;
  final Color accentClr;
  final Color subtitleClr;
  final BuildContext ctx;

  const _RangeRow({
    required this.label,
    required this.page,
    required this.accentClr,
    required this.subtitleClr,
    required this.ctx,
    this.surahLine,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.madReg14(ctx, color: subtitleClr)),
            if (surahLine != null) ...[
              SizedBox(height: 2.h),
              Text(surahLine!,
                  style: AppTextStyles.madReg12(ctx, color: subtitleClr)),
            ],
          ],
        ),
        Text(
          page,
          style: AppTextStyles.madB24(ctx, color: accentClr),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════
// OVERALL PROGRESS CARD  (compact)
// ══════════════════════════════════════════════════
class _OverallProgressCard extends StatelessWidget {
  final RecitationCubit cubit;
  final bool gold;
  final bool isDark;
  final Color accentClr;
  final Color textClr;
  final Color borderClr;
  final Color subtitleClr;
  final BuildContext context;

  const _OverallProgressCard({
    required this.cubit,
    required this.gold,
    required this.isDark,
    required this.accentClr,
    required this.textClr,
    required this.borderClr,
    required this.subtitleClr,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gold
              ? [
            const Color(AppColors.goldPrimary),
            const Color(AppColors.goldAccent),
          ]
              : [
            Color(AppColors.mainGreen),
            Color(AppColors.mainGreen).withOpacity(0.75),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        children: [
          // ── Percentage + page counter ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تقدمك الكلي',
                    style: AppTextStyles.madReg12(ctx, color: Colors.white70),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${cubit.progressPercentage.toStringAsFixed(1)}%',
                    style: AppTextStyles.madB32(ctx, color: Colors.white),
                  ),
                ],
              ),
              Text(
                'ص ${cubit.currentPage} / ${cubit.totalPages}',
                style: AppTextStyles.madReg14(ctx, color: Colors.white70),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: cubit.currentPage / cubit.totalPages,
              minHeight: 8.h,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor:
              const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          SizedBox(height: 16.h),

          // ── 3 compact stats ──
          IntrinsicHeight(
            child: Row(
              children: [
                _CompactStat(
                  label: 'صفحات متبقية',
                  value: '${cubit.totalPagesRemaining}',
                  ctx: ctx,
                ),
                _VerticalDivider(),
                _CompactStat(
                  label: 'أيام للإنهاء',
                  value:
                  '${(cubit.totalPagesRemaining / cubit.dailyPagesTarget).ceil()}',
                  ctx: ctx,
                ),
                if (cubit.daysLate > 0) ...[
                  _VerticalDivider(),
                  _CompactStat(
                    label: 'أيام التأخير',
                    value: '${cubit.daysLate}',
                    ctx: ctx,
                    isWarning: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext ctx;
  final bool isWarning;

  const _CompactStat({
    required this.label,
    required this.value,
    required this.ctx,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.madB20(ctx,
                color: isWarning ? Colors.yellow : Colors.white),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: AppTextStyles.madReg10(ctx, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: double.infinity,
      color: Colors.white.withOpacity(0.3),
      margin: EdgeInsets.symmetric(horizontal: 8.w),
    );
  }
}

// ══════════════════════════════════════════════════
// RAFEQ BANNER  (reusable, unchanged)
// ══════════════════════════════════════════════════
class _RafeqBanner extends StatelessWidget {
  final String imagePath;
  final String message;
  final bool gold;
  final bool isDark;
  final Color accentColor;
  final bool showBadge;

  const _RafeqBanner({
    required this.imagePath,
    required this.message,
    required this.gold,
    required this.isDark,
    required this.accentColor,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/rafeq_bg.png',
                fit: BoxFit.fill,
              ),
            ),
          ),
          Positioned(
            left: 20.w,
            child: Image.asset(
              imagePath,
              height: 110.h,
              width: 90.w,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 35.w,
            left: 110.w,
            child: Text(
              message,
              style: AppTextStyles.madB16(
                context,
                color: gold ? const Color(AppColors.goldAccent) : Colors.white,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          if (showBadge)
            Positioned(
              top: 10.h,
              left: 10.w,
              child: Container(
                padding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, color: Colors.white, size: 12),
                    SizedBox(width: 4.w),
                    Text(
                      'أتممت اليوم',
                      style: AppTextStyles.madReg10(context,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}