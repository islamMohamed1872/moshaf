import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_textstyles.dart';


class AzkarHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final bool showBorder;
  final Color? iconColor;

  const AzkarHeader({
    Key? key,
    required this.title,
    this.onBack,
    this.showBorder = true,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsetsDirectional.symmetric(horizontal: 20.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.madReg16(context),
          ),
          InkWell(
            onTap: onBack ?? () => Navigator.pop(context),
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
                border: showBorder
                    ? Border.all(
                  color: Color(AppColors.containerBorders),
                )
                    : null,
              ),
              child: FittedBox(
                child: Icon(
                  context.locale.languageCode == "ar"
                      ? Icons.arrow_forward_ios
                      : Icons.arrow_back_ios,
                  color: iconColor ?? Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
