import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moshaf/constants/app_colors.dart';

import '../../../constants/app_textstyles.dart';

class CustomSorahContainer extends StatelessWidget {
  final int sorahIndex;
  final String placeOfRevelation;
  final int verseCount;
  final VoidCallback onReadPressed;
  final VoidCallback onListenPressed;
  final Color? borderColor;
  final double? height;
  final bool isDark;
  const CustomSorahContainer({
    super.key,
    required this.placeOfRevelation,
    required this.verseCount,
    required this.sorahIndex,
    required this.onReadPressed,
    required this.onListenPressed,
    this.borderColor,
    this.height,
    required this.isDark
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // height: height ?? 55.h,
      padding: EdgeInsets.symmetric(vertical: 10,horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: borderColor ?? Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders),
        ),
      ),
      child: Row(
        spacing: 10.w,
        children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
                text: TextSpan(text: (sorahIndex+1).toString(),
                  style: AppTextStyles.arsura24(context,color: isDark?Colors.white:Colors.black),
                )),
            Text("$placeOfRevelation | $verseCount ايات",
            style: AppTextStyles.madXL10(context,color: Color(isDark?AppColors.containerDarkBorders:0xff848484)),
            )
          ],
        ),
          const Spacer(),
          InkWell(
              onTap: onReadPressed,
              child: Icon(FontAwesomeIcons.solidFileLines,color:isDark? Colors.white:Colors.black,size: 20,)),
          InkWell(
            onTap: onListenPressed,
            child: Container(
              width: 25.w,
              height: 25.w,
              padding: EdgeInsets.all(5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff0F9D58),
              ),
              child: const FittedBox(
                child: Icon(
                  FontAwesomeIcons.play,
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
