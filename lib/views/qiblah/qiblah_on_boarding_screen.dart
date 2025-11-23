import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/qiblah/qiblah_cubit.dart';
import 'package:moshaf/controllers/qiblah/qiblah_states.dart';
import 'package:moshaf/views/qiblah/qiblah_screen.dart';
import 'package:moshaf/views/widgets/custom_green_button.dart';

import '../../constants/app_colors.dart';
import '../../controllers/theme/theme_cubit.dart';

class QiblahOnBoardingScreen extends StatelessWidget {
  const QiblahOnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    final gold = AppColors.isGoldMode;

    // ------- Colors -------
    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final textClr =
    gold ? const Color(AppColors.goldText) : (isDark ? Colors.white : Colors.black);

    final overlayBg = gold
        ? const Color(AppColors.goldAccent)
        : (isDark ? Color(0xff3E3E3E).withOpacity(0.8) : const Color(0xffBFBFBF));

    return BlocConsumer<QiblahCubit, QiblahStates>(
      builder: (context, state) {
        final cubit = QiblahCubit.get(context);
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(end: 20),
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 15, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: borderClr),
                      ),
                      child: Text(
                        "تخطي",
                        style: AppTextStyles.madReg14(context, color: textClr),
                      ),
                    ),
                  ),

                  const Spacer(),

                  Image.asset("assets/images/kaabah.png"),

                  const Spacer(),

                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 19, vertical: 26),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: overlayBg,
                    ),
                    child: Column(
                      spacing: 10.h,
                      children: [
                        Text(
                          "تحديد القبلة",
                          style:
                          AppTextStyles.madB20(context, color: textClr),
                        ),
                        Text(
                          "قَدْ نَرَى تَقَلُّبَ وَجْهِكَ فِي السَّمَاءِ فَلَنُوَلِّيَنَّكَ قِبْلَةً تَرْضَاهَا فَوَلِّ وَجْهَكَ شَطْرَ الْمَسْجِدِ الْحَرَامِ وَحَيْثُ مَا كُنْتُمْ فَوَلُّوا وُجُوهَكُمْ شَطْرَهُ",
                          style:
                          AppTextStyles.madReg16(context, color: textClr),
                        ),

                        // 🟡 Custom Green Button auto-detects gold mode
                        CustomGreenButton(
                          text: "تحديد موقعك لتوجيهك نحو القبلة",
                          onTap: () => cubit.checkPermission(context, isDark),
                          color: gold?Color(AppColors.goldPrimary):null,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      listener: (context, state) {
        if (state is GetPermissionSuccessState) {
          navigateTo(context, QiblahCompassScreen());
        }
      },
    );
  }
}
