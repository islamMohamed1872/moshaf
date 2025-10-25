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
  const Header({super.key,required this.title,this.onTap,required this.isDark,this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 20.0,
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
            style: AppTextStyles.madReg16(context,color:isDark? Colors.white:Colors.black),
          ),
          InkWell(
            onTap:onTap?? () {
              Navigator.pop(context);
            },
            child: Container(
              width: 30.w
              ,
              height: 30.w,
              padding: EdgeInsetsDirectional.only(
                start:
                context.locale.languageCode == "ar" ? 0 : 7.w,
                top: 5,
                bottom: 5,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders),
                ),
              ),
              child: FittedBox(
                child: Icon(
                  context.locale.languageCode == "ar"
                      ? Icons.arrow_forward_ios
                      : Icons.arrow_back_ios,
                  color:iconColor??Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
