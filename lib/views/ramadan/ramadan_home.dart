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
import 'package:moshaf/controllers/ramadan/ramadan_cubit.dart';
import 'package:moshaf/controllers/ramadan/ramadan_states.dart';
import 'package:moshaf/views/home/widgets/animated_prayer_container.dart';
import 'package:moshaf/views/settings/settings_screen.dart';
import 'package:moshaf/views/widgets/header.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../controllers/theme/theme_cubit.dart';
import '../widgets/custom_green_button.dart';

class RamadanHome extends StatelessWidget {
  const RamadanHome({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeState) {
        final isDark = ThemeCubit.get(context).isDark;

        final borderClr = AppColors.isGoldMode
            ? const Color(AppColors.goldBorder)
            : Color(isDark
            ? AppColors.containerDarkBorders
            : AppColors.containerLightBorders);

        final textClr = AppColors.isGoldMode
            ? const Color(AppColors.goldText)
            : (isDark ? Colors.white : Colors.black);

        final iconClr = AppColors.isGoldMode
            ? const Color(AppColors.goldPrimary)
            : const Color(AppColors.mainGreen);

        return BlocListener<RamadanCubit, RamadanStates>(
          listener: (context, state) async {

          },
          child: BlocBuilder<HomeCubit, HomeStates>(
            builder: (context, state) {
              final cubit = RamadanCubit.get(context);

              return Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Header(title: "شهر رمضان المبارك", textColor: isDark?Colors.white:Colors.black,isDark: isDark,iconColor: isDark?Colors.white:Colors.black,),
                        SizedBox(height: 25.h),

                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: cubit.gridItems.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 15.h,
                                    crossAxisSpacing: 15.w,
                                    childAspectRatio: 1.3,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = cubit.gridItems[index];

                                    return Container(
                                      key: Key("ramadan$index"), // ✅ key must be on container
                                      child: InkWell(
                                        onTap: () =>
                                            cubit.navigateToFeature(context, index, isDark),
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
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                item["title"]!,
                                                textAlign: TextAlign.center,
                                                style: AppTextStyles.madB16(
                                                  context,
                                                  color: textClr,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                SizedBox(height: 20.h),

                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
