import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/constants/azkar.dart';
import 'package:moshaf/controllers/azkar/azkar_cubit.dart';
import 'package:moshaf/controllers/azkar/azkar_states.dart';
import 'package:moshaf/views/azkar/names_of_allah.dart';
import 'package:moshaf/views/azkar/prays_screen.dart';
import 'package:moshaf/views/azkar/widgets/custom_azkar_container.dart';
import 'package:moshaf/views/azkar/zekr_screen.dart';
import 'package:moshaf/views/home/home_screen.dart';
import 'package:moshaf/views/widgets/header.dart';

import '../../constants/app_colors.dart';
import '../../controllers/theme/theme_cubit.dart';

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);

    // 🔹 GOLD MODE
    final gold = AppColors.isGoldMode;
    final bgOverlay = gold
        ? const Color(AppColors.goldBackground)
        : (isDark ? const Color(0xFF151515) : Colors.white);

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    return BlocBuilder<AzkarCubit, AzkarStates>(
      builder: (context, state) {
        final cubit = AzkarCubit.get(context);

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ---------------- HEADER ----------------
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        "assets/images/masaa_azkar.png",
                        height: 220.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),

                      Container(
                        height: 220.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0),
                              bgOverlay,
                            ],
                          ),
                        ),
                      ),

                      Positioned(
                        top: 15,
                        left: 0,
                        right: 0,
                        child: Header(
                          title: cubit.zekrCategory,
                          onTap: () => navigateAndFinish(context, const HomeScreen()),
                          isDark: isDark,
                          iconColor: gold ? const Color(AppColors.goldAccent) : null,
                        ),
                      ),

                      Positioned(
                        left: 10,
                        right: 10,
                        child: Text(
                          cubit.randomZekr,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.kufi24(
                            context,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // ---------------- TABS ----------------
                      Positioned(
                        bottom: 0,
                        child: Row(
                          children: [
                            // أذكار
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 9.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(45),
                                border: Border.all(color: borderClr),
                              ),
                              child: Text(
                                "اذكار",
                                style: AppTextStyles.madMd12(
                                  context,
                                  color: textClr,
                                ),
                              ),
                            ),

                            // أدعية
                            InkWell(
                              onTap: () {
                                cubit.getRandomDuaa();
                                navigateTo(context, const PraysScreen());
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 9.w, vertical: 3.h),
                                child: Text(
                                  "ادعية",
                                  style: AppTextStyles.madMd12(
                                    context,
                                    color: textClr,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ---------------- DIVIDER ----------------
                  Container(
                    height: 1,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    color: borderClr,
                  ),

                  // ---------------- CONTENT ----------------
                  _buildCategoryList(context, isDark, gold),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // CATEGORY LIST
  // ----------------------------------------------------
  Widget _buildCategoryList(BuildContext context, bool isDark, bool gold) {
    return Column(
      children: [
        // اسماء الله الحسنى
        CustomAzkarContainer(
          startPadding: 13,
          endPadding: 13,
          isDark: isDark,
          onTap: () => navigateTo(context, NamesOfAllah(isDark: isDark)),
          text: "اسماء الله الحسنى",
          image: "assets/images/asmaa_allah.png",
        ),
        SizedBox(height: 8.h),

        // الصباح & المساء
        Row(
          spacing: 7,
          children: [
            Expanded(
              child: CustomAzkarContainer(
                startPadding: 13,
                isDark: isDark,
                onTap: () => navigateTo(
                    context,
                    ZekrScreen(
                        title: "اذكار الصباح",
                        items: AzkarConstants.azkarSabah)),
                text: "اذكار الصباح",
                image: "assets/images/azkar_sabah.png",
              ),
            ),
            Expanded(
              child: CustomAzkarContainer(
                endPadding: 13,
                isDark: isDark,
                onTap: () => navigateTo(
                    context,
                    ZekrScreen(
                        title: "اذكار المساء",
                        items: AzkarConstants.azkarMasaa)),
                text: "اذكار المساء",
                image: "assets/images/azkar_masaa.png",
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // بعد الصلاة
        CustomAzkarContainer(
          startPadding: 13,
          endPadding: 13,
          isDark: isDark,
          onTap: () => navigateTo(
              context,
              ZekrScreen(
                  title: "اذكار بعد الصلاة",
                  items: AzkarConstants.azkarBaadAlsalah)),
          text: "اذكار بعد الصلاة",
          image: "assets/images/prayer_azkar.png",
        ),
        SizedBox(height: 8.h),

        // الاستيقاظ & النوم
        Row(
          spacing: 7,
          children: [
            Expanded(
              child: CustomAzkarContainer(
                startPadding: 13,
                isDark: isDark,
                onTap: () => navigateTo(
                    context,
                    ZekrScreen(
                        title: "اذكار الاستيقاظ",
                        items: AzkarConstants.azkarAlIstiqaz)),
                text: "اذكار الاستيقاظ",
                image: "assets/images/wakeup_azkar.png",
              ),
            ),
            Expanded(
              child: CustomAzkarContainer(
                endPadding: 13,
                isDark: isDark,
                onTap: () => navigateTo(
                    context,
                    ZekrScreen(
                        title: "اذكار النوم",
                        items: AzkarConstants.azkarAlNawm)),
                text: "اذكار النوم",
                image: "assets/images/sleep_azkar.png",
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // اذكار متفرقة
        CustomAzkarContainer(
          startPadding: 13,
          endPadding: 13,
          isDark: isDark,
          onTap: () => navigateTo(
              context,
              ZekrScreen(
                  title: "اذكار متفرقة",
                  items: AzkarConstants.azkarMotafareqa)),
          text: "اذكار متفرقة",
          image: "assets/images/seperated_azkar.png",
        ),
        SizedBox(height: 8.h),

        // الاذان & المسجد
        Row(
          spacing: 7,
          children: [
            Expanded(
              child: CustomAzkarContainer(
                startPadding: 13,
                isDark: isDark,
                onTap: () => navigateTo(
                    context,
                    ZekrScreen(
                        title: "اذكار الاذان",
                        items: AzkarConstants.azkarAlAdhan)),
                text: "اذكار الاذان",
                image: "assets/images/adhan_azkar.png",
              ),
            ),
            Expanded(
              child: CustomAzkarContainer(
                endPadding: 13,
                isDark: isDark,
                onTap: () => navigateTo(
                    context,
                    ZekrScreen(
                        title: "اذكار المسجد",
                        items: AzkarConstants.azkarAlMasjid)),
                text: "اذكار المسجد",
                image: "assets/images/mosque_azkar.png",
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // الطعام & الوضوء
        Row(
          spacing: 7,
          children: [
            Expanded(
              child: CustomAzkarContainer(
                startPadding: 13,
                isDark: isDark,
                onTap: () => navigateTo(
                    context,
                    ZekrScreen(
                        title: "اذكار الطعام",
                        items: AzkarConstants.azkarAlTaam)),
                text: "اذكار الطعام",
                image: "assets/images/food_azkar.png",
              ),
            ),
            Expanded(
              child: CustomAzkarContainer(
                endPadding: 13,
                isDark: isDark,
                onTap: () => navigateTo(
                    context,
                    ZekrScreen(
                        title: "اذكار الوضوء",
                        items: AzkarConstants.azkarAlWudu)),
                text: "اذكار الوضوء",
                image: "assets/images/ablution_azkar.png",
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        // الحج والعمرة & المنزل
        Row(
          spacing: 7,
          children: [
            Expanded(
              child: CustomAzkarContainer(
                startPadding: 13,
                isDark: isDark,
                onTap: () => navigateTo(
                    context,
                    ZekrScreen(
                        title: "اذكار الحج والعمرة",
                        items: AzkarConstants.azkarAlHajjWalUmrah)),
                text: "اذكار الحج والعمرة",
                image: "assets/images/haj_azkar.png",
              ),
            ),
            Expanded(
              child: CustomAzkarContainer(
                endPadding: 13,
                isDark: isDark,
                onTap: () => navigateTo(
                    context,
                    ZekrScreen(
                        title: "اذكار المنزل",
                        items: AzkarConstants.azkarAlManzil)),
                text: "اذكار المنزل",
                image: "assets/images/home_azkar.png",
              ),
            ),
          ],
        ),
      ],
    );
  }
}
