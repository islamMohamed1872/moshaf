import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';

class Header extends StatelessWidget {
  final String title;
  final GestureTapCallback? onTap;
  final bool isDark;
  final Color? iconColor;

  const Header({
    super.key,
    required this.title,
    this.onTap,
    required this.isDark,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // 🟨 Smart color adaptation
    final bool goldMode = AppColors.isGoldMode;
    final Color borderColor = goldMode
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

    final Color textColor = goldMode
        ? const Color(AppColors.goldText)
        :  Colors.white;

    final Color iconClr = iconColor ??
        (goldMode
            ? const Color(AppColors.goldPrimary)
            : Colors.white);

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 20.0,
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🕌 Title
          Expanded(
            child: Text(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              title,
              style: AppTextStyles.madReg16(
                context,
                color: textColor,
              ),
            ),
          ),

          // ◀️ Back Button
          InkWell(
            onTap: onTap ?? () => Navigator.pop(context),
            child: Container(
              width: 30.w,
              height: 30.w,
              padding: EdgeInsetsDirectional.only(
                start: context.locale.languageCode == "ar" ? 0 : 7.w,
                top: 5,
                bottom: 5,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: FittedBox(
                child: Icon(
                  context.locale.languageCode == "ar"
                      ? Icons.arrow_forward_ios
                      : Icons.arrow_back_ios,
                  color: iconClr,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
