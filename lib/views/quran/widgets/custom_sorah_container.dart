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
  final VoidCallback onRowPressed;
  final VoidCallback onListenPressed;
  final Color? borderColor;
  final double? height;
  final bool isDark;

  const CustomSorahContainer({
    super.key,
    required this.placeOfRevelation,
    required this.verseCount,
    required this.sorahIndex,
    required this.onRowPressed,
    required this.onReadPressed,
    required this.onListenPressed,
    this.borderColor,
    this.height,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.isGoldMode;

    // Colors
    final borderClr = borderColor ??
        (gold
            ? const Color(AppColors.goldBorder)
            : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders));

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final subTextClr = gold
        ? const Color(AppColors.goldText)
        : Color(isDark ? AppColors.containerDarkBorders : 0xff848484);

    final iconClr = gold ? const Color(AppColors.goldPrimary) : (isDark ? Colors.white : Colors.black);

    final playButtonColor = gold ? const Color(AppColors.goldPrimary) : const Color(0xff0F9D58);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: borderClr),
      ),
      child: InkWell(
        onTap: onRowPressed,
        child: Row(
          spacing: 10.w,
          children: [
            /// LEFT - Surah Number / Metadata
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: (sorahIndex + 1).toString(),
                    style: AppTextStyles.arsura24(context, color: textClr),
                  ),
                ),
                Text(
                  "$placeOfRevelation | $verseCount آيات",
                  style: AppTextStyles.madXL10(context, color: subTextClr),
                ),
              ],
            ),

            const Spacer(),

            /// READ BUTTON
            InkWell(
              onTap: onReadPressed,
              child: Icon(
                FontAwesomeIcons.solidFileLines,
                color: iconClr,
                size: 20,
              ),
            ),

            /// LISTEN BUTTON
            InkWell(
              onTap: onListenPressed,
              child: Container(
                width: 25.w,
                height: 25.w,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: playButtonColor,
                ),
                child: const FittedBox(
                  child: Icon(
                    FontAwesomeIcons.play,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
