import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/home/home_cubit.dart';
import 'package:moshaf/controllers/home/home_states.dart';
import 'package:moshaf/controllers/prayer_times/prayer_times_cubit.dart';
import 'package:moshaf/controllers/prayer_times/prayer_times_states.dart';
import 'package:moshaf/views/home/widgets/animated_prayer_container.dart';
import 'package:moshaf/views/settings/settings_screen.dart';
import 'package:moshaf/views/widgets/custom_green_button.dart';

import '../../controllers/theme/theme_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showFirstTimeDialog(BuildContext context, HomeCubit cubit,bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(15.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    cubit.setFirstTime();
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: const BoxDecoration(
                      color: Color(0xff353535),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsetsDirectional.only(start: 25.w, end: 25.w, top: 40.h),
                decoration: BoxDecoration(
                  color: const Color(0xff0F9D58),
                  borderRadius: BorderRadius.circular(15),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  "assets/images/mostakeem_preview.png",
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 30.h),
              Text(
                "اهدنا الصراط المستقيم",
                style: AppTextStyles.madB20(context).copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              CustomGreenButton(
                text: "ابدأ الآن",
                onTap: () {
                  Navigator.pop(context);
                  cubit.setFirstTime();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeState) {
        final themeCubit = ThemeCubit.get(context);
        final isDark = themeCubit.isDark;

        final borderClr = AppColors.isGoldMode
            ? const Color(AppColors.goldBorder)
            : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

        final textClr = AppColors.isGoldMode
            ? const Color(AppColors.goldText)
            : (isDark ? Colors.white : Colors.black);

        final iconClr = AppColors.isGoldMode
            ? const Color(AppColors.goldPrimary)
            : const Color(AppColors.mainGreen);

        return BlocBuilder<HomeCubit, HomeStates>(
          builder: (context, state) {
            final cubit = HomeCubit.get(context);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (cubit.isFirstTime == true) {
                _showFirstTimeDialog(context, cubit, isDark);
              }
            });

            return Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/mostakeem_logo.png",
                        width: 250.w,
                      ),
                      SizedBox(height: 25.h),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(children: [

                            BlocBuilder<PrayerTimesCubit, PrayerTimesStates>(
                              builder: (context, state) {
                                final c = PrayerTimesCubit.get(context);
                                return AnimatedPrayerContainer(
                                  isDark: isDark,
                                  prayerName: c.upComingPrayer,
                                  remainingTime: c.remainingTime,
                                  dayName: c.getDayName(),
                                  hijriDate: c.hijriDate,
                                  date: c.date,
                                );
                              },
                            ),

                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cubit.gridItems.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 15.h,
                                crossAxisSpacing: 15.w,
                                childAspectRatio: 1.3.h,
                              ),
                              itemBuilder: (context, index) {
                                final item = cubit.gridItems[index];
                                return InkWell(
                                  onTap: () => cubit.navigateToFeature(context, index, isDark),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: EdgeInsetsDirectional.symmetric(
                                      vertical: 10.h,
                                      horizontal: 20.w,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: borderClr),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Image.asset(
                                            item["image"]!,
                                            width: 50.w,
                                            height: 50.w,
                                          ),
                                        ),
                                        Text(
                                          item["title"]!,
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.madB16(
                                            context,
                                            color: textClr,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 20.h),

                            InkWell(
                              onTap: () {
                                navigateTo(context, SettingsScreen());
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: EdgeInsetsDirectional.symmetric(
                                  vertical: 10.h,
                                  horizontal: 20.w,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderClr),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 5,
                                  children: [
                                    Icon(FontAwesomeIcons.gear, color: iconClr),
                                    Text("الإعدادات",
                                        style: AppTextStyles.madB16(context, color: textClr)),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 20.h),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

}


