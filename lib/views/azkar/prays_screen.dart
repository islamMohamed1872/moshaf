import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/azkar.dart';
import 'package:moshaf/views/azkar/one_pray_screen.dart';
import 'package:moshaf/views/azkar/widgets/custom_azkar_container.dart';
import 'package:moshaf/views/widgets/header.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../../controllers/azkar/azkar_cubit.dart';
import '../../controllers/azkar/azkar_states.dart';
import '../home/home_screen.dart';

class PraysScreen extends StatelessWidget {
  const PraysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);

    // 🔹 GOLD MODE
    final gold = AppColors.isGoldMode;

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final accentClr = gold
        ? const Color(AppColors.goldPrimary)
        : Color(AppColors.mainGreen);

    return BlocBuilder<AzkarCubit, AzkarStates>(
      builder: (context, state) {
        final cubit = AzkarCubit.get(context);

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ========================= HEADER BG =========================
                  Stack(
                    alignment: AlignmentGeometry.center,
                    children: [
                      Image.asset(
                        "assets/images/prays_bg.png",
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
                              gold
                                  ? const Color(AppColors.goldBackground)
                                  : isDark
                                  ? const Color(0xFF151515)
                                  : Colors.white,
                            ],
                          ),
                        ),
                      ),

                      // ========================= HEADER TITLE =========================
                      Positioned(
                        top: 15,
                        right: 0,
                        left: 0,
                        child: Header(
                          title: cubit.doaaCategory,
                          onTap: () => navigateAndFinish(context, HomeScreen()),
                          isDark: isDark,
                          iconColor: gold ? const Color(AppColors.goldAccent) : null,
                        ),
                      ),

                      // ========================= RANDOM DUA =========================
                      Positioned(
                        right: 10,
                        left: 10,
                        child: Text(
                          cubit.randomDoaa,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.kufi24(
                            context,
                            color: gold ? const Color(AppColors.goldAccent) : Colors.white,
                          ),
                        ),
                      ),

                      // ========================= FOOTER TABS =========================
                      Positioned(
                        bottom: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Back to Azkar
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: EdgeInsetsDirectional.symmetric(
                                    horizontal: 9.w, vertical: 3.h),
                                child: Text(
                                  "اذكار",
                                  style: AppTextStyles.madMd12(context, color: textClr),
                                ),
                              ),
                            ),

                            // Doaa (Selected)
                            Container(
                              padding: EdgeInsetsDirectional.symmetric(
                                  horizontal: 9.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(45),
                                border: Border.all(color: borderClr),
                              ),
                              child: Text(
                                "ادعية",
                                style: AppTextStyles.madMd12(
                                  context,
                                  color:  textClr,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ========================= DIVIDER =========================
                  Container(
                    width: double.infinity,
                    height: 1,
                    margin: EdgeInsetsDirectional.symmetric(vertical: 10),
                    color: borderClr,
                  ),

                  // ========================= ALL PRAY CARDS =========================

                  _azkarItem(
                    context,
                    isDark,
                    gold,
                    label: "جوامع الدعاء",
                    item: AzkarConstants.jawameDoaa,
                  ),

                  _pair(
                    context,
                    isDark,
                    gold,
                    leftLabel: "ادعية نبوية",
                    leftItem: AzkarConstants.adeyahNabaweyah,
                    rightLabel: "ادعية القرآنية",
                    rightItem: AzkarConstants.adeyaQuranya,
                  ),

                  _azkarItem(
                    context,
                    isDark,
                    gold,
                    label: "ادعية الانبياء",
                    item: AzkarConstants.adeyatAlanbiya,
                  ),

                  _pair(
                    context,
                    isDark,
                    gold,
                    leftLabel: "ادعية للميت",
                    leftItem: AzkarConstants.adeyatAlmayet,
                    rightLabel: "ادعية للمسلمين",
                    rightItem: AzkarConstants.adeyaForAllMuslims,
                  ),

                  _azkarItem(
                    context,
                    isDark,
                    gold,
                    label: "فضل السور",
                    item: AzkarConstants.fadlAlSowar,
                  ),

                  _pair(
                    context,
                    isDark,
                    gold,
                    leftLabel: "فضل الدعاء",
                    leftItem: AzkarConstants.fadlAlDoaa,
                    rightLabel: "فضل الذكر",
                    rightItem: AzkarConstants.fadlAlThekr,
                  ),

                  _pair(
                    context,
                    isDark,
                    gold,
                    leftLabel: "الرقية بالسنة",
                    leftItem: AzkarConstants.roqyaBelsonah,
                    rightLabel: "الرقية بالقرآن",
                    rightItem: AzkarConstants.roqyaBelquran,
                  ),

                  _azkarItem(
                    context,
                    isDark,
                    gold,
                    label: "الأربعون النووية",
                    item: AzkarConstants.fortyHadithOfNawawi,
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ========================= HELPERS =========================

  Widget _azkarItem(
      BuildContext context,
      bool isDark,
      bool gold, {
        required String label,
        required Map item,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: CustomAzkarContainer(
        startPadding: 13,
        endPadding: 13,
        isDark: isDark,
        onTap: () {
          navigateTo(
            context,
            OnePrayScreen(
              title: label,
              items: item,
              // isDark: isDark,
            ),
          );
        },
        text: label,
        image: "assets/images/pray2.png",
      ),
    );
  }

  Widget _pair(
      BuildContext context,
      bool isDark,
      bool gold, {
        required String leftLabel,
        required Map leftItem,
        required String rightLabel,
        required Map rightItem,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        spacing: 8.w,
        children: [
          Expanded(
            child: CustomAzkarContainer(
              startPadding: 13,
              isDark: isDark,
              onTap: () {
                navigateTo(
                  context,
                  OnePrayScreen(
                    title: leftLabel,
                    items: leftItem,
                    // isDark: isDark,
                  ),
                );
              },
              text: leftLabel,
              image: "assets/images/pray2.png",
            ),
          ),
          Expanded(
            child: CustomAzkarContainer(
              endPadding: 13,
              isDark: isDark,
              onTap: () {
                navigateTo(
                  context,
                  OnePrayScreen(
                    title: rightLabel,
                    items: rightItem,
                    // isDark: isDark,
                  ),
                );
              },
              text: rightLabel,
              image: "assets/images/pray2.png",
            ),
          ),
        ],
      ),
    );
  }
}
