import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64.w,
        height: 28.h,
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF008932) : Colors.grey.shade500,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment:
          value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 39.w,
            height: 22.w,
            decoration:  BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100)
            ),
          ),
        ),
      ),
    );
  }
}
