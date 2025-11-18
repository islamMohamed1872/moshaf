import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moshaf/components/cache_helper.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/views/widgets/custom_green_button.dart';
import 'package:moshaf/views/widgets/header.dart';
import 'dart:math';

import '../../controllers/theme/theme_cubit.dart';

class ZakahCalculator extends StatefulWidget {
  const ZakahCalculator({super.key});

  @override
  State<ZakahCalculator> createState() => _ZakahCalculatorState();
}

class _ZakahCalculatorState extends State<ZakahCalculator> {
  final moneyController = TextEditingController();
  double? zakatResult; // stores last computed zakat amount
  String? currency;

  @override
  void dispose() {
    moneyController.dispose();
    super.dispose();
  }

  void _calculateZakat() {
    final text = moneyController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("الرجاء إدخال مبلغ أولاً")),
      );
      return;
    }

    // remove possible thousand separators (commas) and Arabic digits handling basic
    final cleaned = text.replaceAll(',', '').replaceAll('٬', '');

    double? value;
    try {
      // try parse as double
      value = double.parse(cleaned);
    } catch (e) {
      return;
    }

    if (value <= 0) {
      return;
    }

    // compute zakat = 2.5% of the amount
    final zakat = (value * 2.5) / 100.0;

    // round to 2 decimal places
    final zakatRounded = (zakat * 100).roundToDouble() / 100.0;

    setState(() {
      zakatResult = zakatRounded;
    });

  }

  void getCurrencyName()async{
    final String country = await CacheHelper.getData(key: "country")??"مصر";

    setState(() {
      switch (country) {
        case "مصر":
          currency = "جنيه مصري";
          break;

        case "المملكة العربية السعودية":
          currency = "ريال سعودي";
          break;

        case "الإمارات العربية المتحدة":
          currency = "درهم إماراتي";
          break;

        case "الكويت":
          currency = "دينار كويتي";
          break;

        default:
          currency = "العملة غير معروفة";
      }
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrencyName();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    return Scaffold(
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Header(title: "زكاة المال",isDark: isDark,iconColor: isDark?Colors.white:Colors.black,),
                  SizedBox(
                    height: 40.h,
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 17, vertical: 12),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders))),
                    child: RichText(
                        text: TextSpan(children: [
                          TextSpan(text: "فرض إسلامي يُخرَج منها", style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black)),
                          TextSpan(text: " 2.5% ", style: AppTextStyles.madB14(context, color: Color(AppColors.mainGreen))),
                          TextSpan(
                              text:
                              "من الأموال المدخرة التي بلغت النصاب(وهو ما يعادل 85 جرامًا من الذهب أو 595 جرامًا من الفضة) ومر عليها عام",
                              style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black)),
                          TextSpan(text: " هجري كامل ", style: AppTextStyles.madB14(context, color: Color(AppColors.mainGreen))),
                          TextSpan(text: "يجب أن تخرج الزكاة إلى", style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black)),
                          TextSpan(text: " الفقراء والمساكين ", style: AppTextStyles.madB14(context, color: Color(AppColors.mainGreen))),
                          TextSpan(text: "وغيرهم من المصارف المحددة في القرآن الكريم، ويمكن أن تكون نقدًا أو عينيًا", style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black)),
                        ])),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.only(start: 15.w, end: 15.w, top: 10.h),
                          child: IconButton(
                              onPressed: () {
                                // optional: reset result
                                setState(() {
                                  zakatResult = null;
                                  moneyController.clear();
                                });
                              },
                              icon: Icon(
                                FontAwesomeIcons.arrowRotateRight,
                                size: 15.w,
                                color: Color(0xff3E3E3E),
                              )),
                        ),
                        Center(
                          child: SizedBox(
                            height: 120,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Positioned(
                                    top: 0,
                                    child: Text(
                                      zakatResult ==null ? "00" : zakatResult.toString().padLeft(2, "0"),
                                      style: AppTextStyles.madB60(context, color: Color(AppColors.mainGreen)),
                                    )),
                                // show zakat result below amount if present
                                Positioned(
                                  bottom: 8,
                                  child: Text(currency??"جنية مصري", style: AppTextStyles.madL40(context,color: isDark?Colors.white:Colors.black))
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 25.h,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  TextFormField(
                    controller: moneyController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),
                    cursorColor: Color(AppColors.mainGreen),
                    decoration: InputDecoration(
                      hintText: "ادخل المبلغ",
                      hintStyle: AppTextStyles.madReg14(context,color: Color(0xff3E3E3E)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders))),
                      errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders))),
                      focusedBorder:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color(AppColors.mainGreen))),
                    ),
                  ),
                  SizedBox(
                    height: 150.h,
                  ),
                  CustomGreenButton(
                    text: "حساب الزكاة",
                    onTap: _calculateZakat,
                  )
                ],
              ),
            ),
          )),
    );
  }
}
