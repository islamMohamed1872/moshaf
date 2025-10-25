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
  final VoidCallback? onSuffixPressed; // 👈 nullable callback

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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      cursorColor: Color(AppColors.mainGreen),
      validator: validator,
      style: AppTextStyles.madReg12(
        context,
        color:isDark ?Colors.white:Colors.black,
      ),
      decoration: InputDecoration(
        filled: fillColor != null,
        fillColor: fillColor,
        hintText: hintText,
        hintStyle: AppTextStyles.madReg12(
          context,
          color: Color(
            isDark
                ? AppColors.containerDarkBorders
                : 0xff4F4F4F,
          ),
        ),

        // ✅ Add suffix icon only if provided
        suffixIcon: suffixIcon != null
            ? IconButton(
          icon: Icon(
            suffixIcon,
            color: Color(
              isDark
                  ? AppColors.containerDarkBorders
                  : 0xff4F4F4F,
            ),
          ),
          onPressed: onSuffixPressed, // 👈 nullable
        )
            : null,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: Color(
              isDark
                  ? AppColors.containerDarkBorders
                  : AppColors.containerLightBorders,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Color(AppColors.mainGreen)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: Color(
              isDark
                  ? AppColors.containerDarkBorders
                  : AppColors.containerLightBorders,
            ),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
