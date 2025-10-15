import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyles {
  static TextStyle madL14(BuildContext context, {Color? color}) => TextStyle(
    fontFamily: "madL",
    fontSize: 14.sp,
    color: color ?? _getTextColor(context),
  );

  static TextStyle madReg14(BuildContext context, {Color? color}) => TextStyle(
    fontFamily: "madReg",
    fontSize: 14.sp,
    color: color ?? _getTextColor(context),
  );

  static TextStyle madReg18(BuildContext context, {Color? color}) => TextStyle(
    fontFamily: "madReg",
    fontSize: 18.sp,
    color: color ?? _getTextColor(context),
  );

  static TextStyle madReg40(BuildContext context, {Color? color}) => TextStyle(
    fontFamily: "madReg",
    fontSize: 40.sp,
    color: color ?? _getTextColor(context),
  );

  static TextStyle madMd20(BuildContext context, {Color? color}) => TextStyle(
    fontFamily: "madMd",
    fontSize: 20.sp,
    color: color ?? _getTextColor(context),
  );


  static TextStyle madL11(BuildContext context, {Color? color}) => TextStyle(
    fontFamily: "madL",
    fontSize: 11.sp,
    color: color ?? _getTextColor(context),
  );

  static TextStyle madL12(BuildContext context, {Color? color}) => TextStyle(
    fontFamily: "madL",
    fontSize: 12.sp,
    color: color ?? _getTextColor(context),
  );

  static TextStyle madL16(BuildContext context, {Color? color}) => TextStyle(
    fontFamily: "madL",
    fontSize: 16.sp,
    color: color ?? _getTextColor(context),
  );

  static TextStyle kufi24(BuildContext context, {Color? color}) => TextStyle(
    fontFamily: "kufi",
    fontSize: 24.sp,
    color: color ?? _getTextColor(context),
  );

  static Color _getTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

}
