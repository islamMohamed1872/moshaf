import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_textstyles.dart';

class CoachContent extends StatelessWidget {
  final String title;
  final String description;
  final Color titleColor;
  final Color descColor;

  const CoachContent({
    required this.title,
    required this.description,
    required this.titleColor,
    required this.descColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.madB16(context).copyWith(color: titleColor),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: AppTextStyles.madReg12(context).copyWith(color: descColor),
          ),
        ],
      ),
    );
  }
}
