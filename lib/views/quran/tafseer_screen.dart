import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/views/widgets/header.dart';
import 'package:quran/quran.dart' as quran;

import '../../constants/app_colors.dart';
import '../../controllers/theme/theme_cubit.dart';

class TafseerScreen extends StatelessWidget {
  final int ayah;
  final int sorah;
  final String tafseer;

  const TafseerScreen({
    super.key,
    required this.ayah,
    required this.tafseer,
    required this.sorah,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);

    // ⬇️ GOLD MODE COLORS
    final gold = AppColors.isGoldMode;

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final verseTextColor = gold
        ? const Color(AppColors.goldPrimary)
        : Color(AppColors.mainGreen);

    final tafseerTextColor = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final headerIconColor = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final screenBackground = isDark
        ? const Color(AppColors.scaffoldBg)
        : Colors.white;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: gold ? const Color(AppColors.goldBackground) : screenBackground,
          padding: const EdgeInsets.all(14.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Header(
                  title: "تفسير",
                  isDark: isDark,
                  iconColor: headerIconColor,
                ),

                SizedBox(height: 20.h),

                // =============================
                // 🔹 VERSE CONTAINER
                // =============================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 17,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderClr),
                  ),
                  child: Text(
                    quran.getVerse(sorah, ayah),
                    style: AppTextStyles.arsura17(
                      context,
                      color: verseTextColor,
                    ),
                    // textDirection: TextDirection.rtl,
                  ),
                ),

                SizedBox(height: 8),

                // =============================
                // 🔹 TAFSEER CONTAINER
                // =============================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderClr),
                  ),
                  child: Text(
                    tafseer,
                    style: AppTextStyles.madReg14(
                      context,
                      color: tafseerTextColor,
                    ),
                    // textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
