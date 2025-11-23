import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool isDark;
  final bool obscureText;
  final Color? fillColor;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isDark,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.fillColor,
    this.suffixIcon,
    this.onSuffixPressed,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.getBorderColor(isDark: isDark);
    final textColor = AppColors.getTextColor(isDark: isDark);
    final primaryColor = AppColors.getPrimaryColor();

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      cursorColor: primaryColor,
      validator: validator,
      style: AppTextStyles.madReg12(
        context,
        color: textColor,
      ),
      decoration: InputDecoration(
        filled: fillColor != null,
        fillColor: fillColor,

        hintText: hintText,
        hintStyle: AppTextStyles.madReg12(
          context,
          color: borderColor.withOpacity(0.7),
        ),

        suffixIcon: suffixIcon != null
            ? IconButton(
          icon: Icon(
            suffixIcon,
            color: borderColor,
          ),
          onPressed: onSuffixPressed,
        )
            : null,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: borderColor),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: borderColor),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: primaryColor, width: 1.8),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
