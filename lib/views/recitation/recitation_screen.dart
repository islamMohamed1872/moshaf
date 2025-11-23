import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/home/home_cubit.dart';
import 'package:moshaf/controllers/text_quran/text_quran_cubit.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';
import 'package:moshaf/views/widgets/header.dart';
import 'package:quran/quran.dart' as quran;

import '../../controllers/recitation/recitation_cubit.dart';
import '../../controllers/recitation/recitation_state.dart';
import '../quran/widgets/quran_page.dart';

class RecitationScreen extends StatelessWidget {
  const RecitationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RecitationView();
  }
}

class RecitationView extends StatelessWidget {
  const RecitationView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    final gold = AppColors.isGoldMode;

    return Scaffold(
      body: BlocBuilder<RecitationCubit, RecitationStates>(
        builder: (context, state) {
          final cubit = RecitationCubit.get(context);

          if (state is RecitationLoadingState) {
            return Center(
              child: CircularProgressIndicator(
                color: gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen),
              ),
            );
          }

          if (!cubit.hasActiveGoal) {
            return _buildStartGoalView(context, cubit, isDark, gold);
          }

          return _buildActiveGoalView(context, cubit, isDark, gold);
        },
      ),
    );
  }

  // ═══ START GOAL VIEW ═══
  Widget _buildStartGoalView(BuildContext context, RecitationCubit cubit, bool isDark, bool gold) {
    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 40.h),
          Header(title: "الوِرد اليومي", isDark: isDark,iconColor: AppColors.isGoldMode? textClr: isDark?Colors.white:Colors.black,),
          SizedBox(height: 20.h),
          // Icon
          Container(
            padding: EdgeInsets.all(30.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gold
                  ? const Color(AppColors.goldPrimary).withOpacity(0.1)
                  : Color(AppColors.mainGreen).withOpacity(0.1),
              border: Border.all(color: borderClr),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 80.w,
              color: gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen),
            ),
          ),

          SizedBox(height: 30.h),

          Text(
            'ابدأ رحلتك مع القرآن',
            style: AppTextStyles.madB24(context, color: textClr),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 15.h),

          Text(
            'حدد عدد الصفحات التي تريد قراءتها يومياً\nوسنساعدك على إكمال القرآن الكريم',
            style: AppTextStyles.madReg14(context, color: subtitleClr),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 40.h),

          // Pages selector
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
                      onLongPressStart: (_) {
                        cubit.startAutoChange(isIncrement: false);
                      },
                      onLongPressEnd: (_) {
                        cubit.stopAutoChange();
                      },
                      child: Icon(Icons.remove_circle_outline,
                          color: textClr, size: 32.w),
                    ),
                    SizedBox(width: 20.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: gold
                            ? const Color(AppColors.goldPrimary)
                            : Color(AppColors.mainGreen),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${cubit.dailyPagesTarget}',
                        style: AppTextStyles.madB32(context, color: Colors.white),
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
                      onLongPressStart: (_) {
                        cubit.startAutoChange(isIncrement: true);
                      },
                      onLongPressEnd: (_) {
                        cubit.stopAutoChange();
                      },
                      child: Icon(Icons.add_circle_outline,
                          color: textClr, size: 32.w),
                    ),
                  ],
                ),
                SizedBox(height: 15.h),
                Text(
                  'ستنتهي من القرآن في ${(604 / cubit.dailyPagesTarget).ceil()} يوم',
                  style: AppTextStyles.madReg14(context, color: subtitleClr),
                ),
              ],
            ),
          ),

          SizedBox(height: 40.h),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await cubit.startNewGoal(cubit.dailyPagesTarget);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: gold
                    ? const Color(AppColors.goldPrimary)
                    : Color(AppColors.mainGreen),
                padding: EdgeInsets.symmetric(vertical: 15.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // ═══ ACTIVE GOAL VIEW ═══
  Widget _buildActiveGoalView(BuildContext context, RecitationCubit cubit, bool isDark, bool gold) {
    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final subtitleClr = gold
        ? const Color(AppColors.goldText).withOpacity(0.7)
        : (isDark ? Colors.white70 : Colors.black54);

    final dailyRange = cubit.getDailyReadingRange();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Header(title: "الوِرد اليومي", isDark: isDark,iconColor: AppColors.isGoldMode? textClr: isDark?Colors.white:Colors.black,),
            SizedBox(height: 20.h),
            // Progress Card
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: gold
                              ? [const Color(AppColors.goldPrimary), const Color(AppColors.goldAccent)]
                              : [Color(AppColors.mainGreen), Color(AppColors.mainGreen).withOpacity(0.7)],
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'تقدمك',
                                    style: AppTextStyles.madReg14(context, color: Colors.white70),
                                  ),
                                  Text(
                                    '${cubit.progressPercentage.toStringAsFixed(1)}%',
                                    style: AppTextStyles.madB32(context, color: Colors.white),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.all(25.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: FittedBox(
                                  child: Text(
                                    '${cubit.currentPage}/${cubit.totalPages}',
                                    style: AppTextStyles.madB16(context, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: cubit.currentPage / cubit.totalPages,
                              minHeight: 10.h,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                
                    SizedBox(height: 20.h),
                
                    // Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15.w,
                      mainAxisSpacing: 15.h,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard(
                          context,
                          'صفحات اليوم',
                          '${cubit.dailyPagesTarget}',
                          Icons.today,
                          isDark,
                          gold,
                        ),
                        _buildStatCard(
                          context,
                          'صفحات متبقية',
                          '${cubit.pagesRemaining}',
                          Icons.bookmark_outline,
                          isDark,
                          gold,
                        ),
                        _buildStatCard(
                          context,
                          'أيام التأخير',
                          '${cubit.daysLate}',
                          Icons.calendar_today,
                          isDark,
                          gold,
                          isWarning: cubit.daysLate > 0,
                        ),
                        _buildStatCard(
                          context,
                          'أيام للإنهاء',
                          '${(cubit.pagesRemaining / cubit.dailyPagesTarget).ceil()}',
                          Icons.flag,
                          isDark,
                          gold,
                        ),
                      ],
                    ),
                
                    SizedBox(height: 20.h),
                
                    // Today's Reading
                    Text(
                      'قراءة اليوم',
                      style: AppTextStyles.madB18(context, color: textClr),
                    ),
                    SizedBox(height: 10.h),
                
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: borderClr),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'من الصفحة',
                                style: AppTextStyles.madReg14(context, color: subtitleClr),
                              ),
                              Text(
                                '${dailyRange['startPage']}',
                                style: AppTextStyles.madB20(context, color: gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen)),
                              ),
                            ],
                          ),
                          SizedBox(height: 5.h),
                          if (dailyRange['startInfo'] != null)
                            Text(
                              'سورة ${dailyRange['startInfo']['startSurahName']} - آية ${dailyRange['startInfo']['startVerse']}',
                              style: AppTextStyles.madReg12(context, color: subtitleClr),
                            ),
                          Divider(height: 20.h, color: borderClr),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'إلى الصفحة',
                                style: AppTextStyles.madReg14(context, color: subtitleClr),
                              ),
                              Text(
                                '${dailyRange['endPage']}',
                                style: AppTextStyles.madB20(context, color: gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen)),
                              ),
                            ],
                          ),
                          SizedBox(height: 5.h),
                          if (dailyRange['endInfo'] != null)
                            Text(
                              'سورة ${dailyRange['endInfo']['endSurahName']} - آية ${dailyRange['endInfo']['endVerse']}',
                              style: AppTextStyles.madReg12(context, color: subtitleClr),
                            ),
                        ],
                      ),
                    ),
                
                    SizedBox(height: 20.h),
                
                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          navigateTo(
                            context,
                            QuranViewPage(
                              navigatedFromRecitation: true,
                              shouldHighlightText: true,
                              highlightVerse: dailyRange['startInfo']['startVerse'].toString(),
                              jsonData: cubit.suraJsonData,
                              pageNumber: quran.getPageNumber(
                                dailyRange['startInfo']['startSurahNumber'],
                                dailyRange['startInfo']['startVerse'],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.menu_book, size: 20),
                        label:  Text('ابدأ القراءة',style: AppTextStyles.madReg14(context,color: Colors.white),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold
                              ? const Color(AppColors.goldPrimary)
                              : Color(AppColors.mainGreen),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                
                    SizedBox(height: 10.h),
                
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await cubit.markPagesRead(cubit.dailyPagesTarget);
                        },
                        icon: Icon(Icons.check_circle_outline, size: 20,color: AppColors.isGoldMode?Color(AppColors.goldPrimary):isDark?Colors.white:Color(AppColors.mainGreen),),
                        label: Text('أنهيت القراءة',style: AppTextStyles.madReg14(context,color:AppColors.isGoldMode?Color(AppColors.goldPrimary):isDark?Colors.white:Color(AppColors.mainGreen)),),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen),
                          side: BorderSide(
                            color: gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                
                    SizedBox(height: 10.h),
                
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          await _showResetDialog(context, cubit, isDark, gold);
                        },
                        child: Text(
                          'إعادة تعيين الهدف',
                          style: AppTextStyles.madReg14(context, color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      bool isDark,
      bool gold, {
        bool isWarning = false,
      }) {
    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final subtitleClr = gold
        ? const Color(AppColors.goldText).withOpacity(0.7)
        : (isDark ? Colors.white70 : Colors.black54);

    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderClr),
        color: isWarning ? Colors.red.withOpacity(0.1) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 30.w,
            color: isWarning
                ? Colors.red
                : (gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen)),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.madB24(context, color: isWarning ? Colors.red : textClr),
          ),
          Text(
            label,
            style: AppTextStyles.madReg12(context, color: subtitleClr),
            textAlign: TextAlign.center,
          ),
        ],
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

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final cancelTextColor = isDark ? Colors.white70 : Colors.black87;

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: gold
              ? const BorderSide(color: Color(AppColors.goldBorder), width: 1)
              : BorderSide(color: borderClr, width: 1),
        ),

        titlePadding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
        contentPadding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 10.h),
        actionsPadding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 10.h),

        title: Text(
          'إعادة تعيين الهدف',
          textAlign: TextAlign.center,
          style: AppTextStyles.madB18(context, color: textClr),
        ),

        content: Text(
          'هل أنت متأكد؟ سيتم حذف كل التقدم الحالي.',
          textAlign: TextAlign.center,
          style: AppTextStyles.madReg14(context, color: textClr.withOpacity(.8)),
        ),

        actionsAlignment: MainAxisAlignment.spaceBetween,

        actions: [
          // ❌ Cancel Button
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'إلغاء',
              style: AppTextStyles.madReg14(context, color: cancelTextColor),
            ),
          ),

          // 🔥 Confirm Button
          ElevatedButton(
            onPressed: () async {
              await cubit.resetGoal();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
              gold ? const Color(AppColors.goldPrimary) : Colors.red,
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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