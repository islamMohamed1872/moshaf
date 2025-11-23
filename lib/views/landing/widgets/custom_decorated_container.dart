import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/constants/app_colors.dart';
import '../../../constants/app_textstyles.dart';

class CustomDecoratedContainer extends StatelessWidget {
  final String? imagePath;
  final String text;
  final VoidCallback onPressed;
  final Color? borderColor;
  final double? height;
  final bool isDark;

  const CustomDecoratedContainer({
    super.key,
    this.imagePath,
    required this.text,
    required this.onPressed,
    this.borderColor,
    this.height,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final useBorderColor =
        borderColor ?? AppColors.getBorderColor(isDark: isDark);

    final textColor = AppColors.getTextColor(isDark: isDark);

    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: height ?? 45.h,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: useBorderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10.w,
          children: [
            if (imagePath != null)
              Image.asset(imagePath!, height: 22.h),

            Text(
              text,
              style: AppTextStyles.madReg14(
                context,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
