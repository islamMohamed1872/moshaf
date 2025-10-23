import 'package:flutter/material.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';

class CustomOutlinedGreenButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double verticalPadding;
  final Color? color;
  final TextStyle? textStyle;

  const CustomOutlinedGreenButton({
    super.key,
    required this.text,
    required this.onTap,
    this.verticalPadding = 11,
    this.color,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color ?? Color(AppColors.mainGreen)),
        ),
        child: Center(
          child: Text(
            text,
            style: textStyle ??
                AppTextStyles.madB14(
                  context,
                  color: Color(AppColors.mainGreen),
                ),
          ),
        ),
      ),
    );
  }
}
