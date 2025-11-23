import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_textstyles.dart';

class CustomAzkarContainer extends StatelessWidget {
  final String image;
  final String text;
  final GestureTapCallback onTap;
  final double? startPadding;
  final double? endPadding;
  final bool isDark;

  const CustomAzkarContainer({
    super.key,
    required this.text,
    required this.image,
    required this.onTap,
    this.startPadding = 0,
    this.endPadding = 0,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // 🔹 GOLD MODE CHECK
    final gold = AppColors.isGoldMode;

    final borderColor = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

    final textColor = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);


    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: startPadding!,
        end: endPadding!,
      ),
      child: InkWell(
        onTap: onTap,
        splashColor:
        gold ? const Color(AppColors.goldPrimary).withOpacity(0.2) : null,
        highlightColor:
        gold ? const Color(AppColors.goldPrimary).withOpacity(0.1) : null,
        child: Container(
          width: double.infinity,
          height: 50.h,
          padding: EdgeInsetsDirectional.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Image.asset(
                image,
                width: 24.w,
              ),
              Text(
                text,
                style: AppTextStyles.madL14(
                  context,
                  color: textColor, // 🔥 GOLD MODE text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
