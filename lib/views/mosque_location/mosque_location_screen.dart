import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/views/mosque_location/nearest_mosques_screen.dart';
import 'package:moshaf/views/widgets/custom_green_button.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';

class MosqueLocationScreen extends StatelessWidget {
  const MosqueLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    final gold = AppColors.isGoldMode;

    // ---- GOLD COLORS ----
    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

    final textClr =
    gold ? const Color(AppColors.goldText) : (isDark ? Colors.white : Colors.black);

    final bgBoxClr = gold
        ? const Color(AppColors.goldAccent)
        : (isDark
        ? const Color(0xff3E3E3E).withOpacity(0.8)
        : const Color(0xffBFBFBF));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 20.0,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsetsDirectional.symmetric(
                          vertical: 6,
                          horizontal: 19,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(38),
                          border: Border.all(color: borderClr),
                        ),
                        child: Text(
                          "رجوع",
                          style: AppTextStyles.madReg14(
                            context,
                            color: textClr,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Image
              Image.asset(
                "assets/images/mosque_location.png",
                width: 340.w,
                // color: gold ? const Color(AppColors.goldPrimary) : null,
              ),

              const Spacer(),

              // BOTTOM BOX
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 19, vertical: 26),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: bgBoxClr,
                ),
                child: Column(
                  spacing: 10.h,
                  children: [
                    Text(
                      "المساجد القريبة",
                      style: AppTextStyles.madB20(
                        context,
                        color: textClr,
                      ),
                    ),
                    Text(
                      " إِنَّمَا يَعْمُرُ مَسَاجِدَ اللَّهِ مَنْ آمَنَ بِاللَّهِ وَالْيَوْمِ الْآخِرِ وَأَقَامَ الصَّلَاةَ وَآتَى الزَّكَاةَ وَلَمْ يَخْشَ إِلَّا اللَّهَ فَعَسَى أُولَئِكَ أَنْ يَكُونُوا مِنَ الْمُهْتَدِينَُ",
                      style: AppTextStyles.madReg16(
                        context,
                        color: textClr,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // GOLD BUTTON AUTO SWITCH
                    CustomGreenButton(
                      text: "اعثر على أقرب مسجد إلى موقعك",
                      onTap: () {
                        navigateTo(context, MasjidLocatorScreen());
                      },
                      // Force gold color on button if applicable
                      color: gold?Color(AppColors.goldPrimary):null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
