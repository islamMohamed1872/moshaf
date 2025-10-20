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
  const CustomAzkarContainer({
    super.key,
    required this.text,
    required this.image,
    required this.onTap,
    this.startPadding = 0,
    this.endPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsetsDirectional.only(start:startPadding!,end: endPadding!),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 50.h,
          padding: EdgeInsetsDirectional.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(AppColors.containerBorders)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Image.asset(image,width: 24.w,),
              Text(text,
                style: AppTextStyles.madL14(context),
              )
            ],
          ),
        ),
      ),
    );
  }
}
