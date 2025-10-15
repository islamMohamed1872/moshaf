import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/views/landing/widgets/custom_decorated_container.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(
                    "assets/images/mosque_background.png",
                  ),
                  fit: BoxFit.contain,
                  opacity: 0.15,
                alignment: AlignmentGeometry.bottomCenter
              )
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {

                        },
                        child: Container(
                          padding: EdgeInsetsDirectional.symmetric(vertical: 5.h,horizontal: 15.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(AppColors.containerBorders)),
                            borderRadius: BorderRadius.circular(38.r),
                          ),
                          child: Text("تخطي",
                            style: AppTextStyles.madReg14(context),
                        ),
                      ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 50.h,
                  ),
                  Padding(
                    padding:  EdgeInsetsDirectional.symmetric(horizontal: 40.w),
                    child: Image.asset("assets/images/mostakeem_logo.png",
                    ),
                  ),
                  SizedBox(
                    height: 60.h,
                  ),
                  Text("مرحبا بك في مستقيم",
                    style: AppTextStyles.madMd20(context),
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Text("مستقيم تطبيق شامل للمسلمين يساعدهم في ادارة عباداتهم اليومية ومتابعة الفرائض بسهوله وتوقيت الصلاه",
                    style: AppTextStyles.madL11(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 25.h,
                  ),
                  CustomDecoratedContainer(
                      imagePath: "assets/images/google.png",
                      text: "تسجيل الدخول باستخدام جوجل",
                      onPressed: (){

                      }),
                  SizedBox(
                    height: 7.h,
                  ),
                  CustomDecoratedContainer(
                      imagePath: "assets/images/apple.png",
                      text: "تسجيل الدخول باستخدام ابل",
                      onPressed: (){

                      }),
                  SizedBox(
                    height: 7.h,
                  ),
                  CustomDecoratedContainer(
                      imagePath: "assets/images/mail.png",
                      text: "تسجيل الدخول باستخدام بريد الكتروني",
                      onPressed: (){

                      }),
                  SizedBox(
                    height: 30.h,
                  ),
                  Row(
                    children: [
                      Expanded(child: Container(
                        height: 1,
                        color: Color(AppColors.containerBorders),
                      )),
                      Padding(
                        padding: EdgeInsetsDirectional.symmetric(horizontal: 20.w),
                        child: Text(
                          "أو",
                          style: AppTextStyles.madReg14(context),
                        ),
                      ),
                      Expanded(child: Container(
                        height: 1,
                        color: Color(AppColors.containerBorders),
                      )),
                    ],
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Text(
                    "أنضم الينا كزائر",
                    style: AppTextStyles.madReg14(context),
                  ),
                  SizedBox(
                    height: 15.h,
                  ),
                  CustomDecoratedContainer(
                      text: "ابدأ الآن كزائر بدون حساب",
                      onPressed: () {

                      },
                  ),
                ],
              ),
            ),
          ),
      ),
    );
  }
}
