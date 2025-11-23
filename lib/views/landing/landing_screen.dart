import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/auth/auth_cubit.dart';
import 'package:moshaf/controllers/auth/auth_states.dart';
import 'package:moshaf/views/auth/login_screen.dart';
import 'package:moshaf/views/home/home_screen.dart';
import 'package:moshaf/views/landing/widgets/custom_decorated_container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

import '../../controllers/theme/theme_cubit.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);

    final textColor = AppColors.getTextColor(isDark: isDark);
    final borderColor = AppColors.getBorderColor(isDark: isDark);
    final bgColor = AppColors.getBackgroundColor(isDark: isDark);

    return BlocListener<AuthCubit, AuthStates>(
      listener: (context, state) {
        if (state is AuthSignInWithGoogleSuccessState ||
            state is AuthSignInWithAppleSuccessState) {
          navigateAndFinish(context, HomeScreen());
        } else if (state is AuthSignInWithGoogleErrorState) {
          Fluttertoast.showToast(
            msg: state.error,
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            gravity: ToastGravity.BOTTOM,
            fontSize: 16.0,
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("assets/images/mosque_background.png"),
                fit: BoxFit.contain,
                opacity: 0.15,
                alignment: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  /// Skip button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => navigateAndFinish(context, HomeScreen()),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 5.h, horizontal: 15.w),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(38.r),
                          ),
                          child: Text(
                            "تخطي",
                            style: AppTextStyles.madReg14(context,
                                color: textColor),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 50.h),

                  Padding(
                    padding:
                    EdgeInsetsDirectional.symmetric(horizontal: 40.w),
                    child: Image.asset("assets/images/mostakeem_logo.png"),
                  ),

                  SizedBox(height: 60.h),

                  Text(
                    "مرحبا بك في مستقيم",
                    style: AppTextStyles.madMd20(context, color: textColor),
                  ),

                  SizedBox(height: 10.h),

                  Text(
                    "مستقيم تطبيق شامل للمسلمين يساعدهم في ادارة عباداتهم اليومية ومتابعة الفرائض بسهوله وتوقيت الصلاه",
                    style:
                    AppTextStyles.madL11(context, color: textColor),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 25.h),

                  /// Google login
                  CustomDecoratedContainer(
                    imagePath: isDark
                        ? "assets/images/google.png"
                        : "assets/images/light_google.png",
                    text: "تسجيل الدخول باستخدام جوجل",
                    isDark: isDark,
                    onPressed: () =>
                        AuthCubit.get(context).signInWithGoogle(),
                  ),

                  if (Platform.isIOS) ...[
                    SizedBox(height: 7.h),

                    /// Apple login
                    CustomDecoratedContainer(
                      imagePath: isDark
                          ? "assets/images/apple.png"
                          : "assets/images/light_apple.png",
                      text: "تسجيل الدخول باستخدام ابل",
                      isDark: isDark,
                      onPressed: () =>
                          AuthCubit.get(context).signInWithApple(),
                    ),
                  ],

                  SizedBox(height: 7.h),

                  /// Email login
                  CustomDecoratedContainer(
                    imagePath: isDark
                        ? "assets/images/mail.png"
                        : "assets/images/light_email.png",
                    text: "تسجيل الدخول باستخدام بريد الكتروني",
                    isDark: isDark,
                    onPressed: () => navigateTo(context, LoginScreen()),
                  ),

                  SizedBox(height: 30.h),

                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 1, color: borderColor),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Text(
                          "أو",
                          style: AppTextStyles.madReg14(context,
                              color: textColor),
                        ),
                      ),
                      Expanded(
                        child: Container(height: 1, color: borderColor),
                      ),
                    ],
                  ),

                  SizedBox(height: 10.h),

                  Text(
                    "أنضم الينا كزائر",
                    style: AppTextStyles.madReg14(context, color: textColor),
                  ),

                  SizedBox(height: 15.h),

                  /// Continue as guest
                  CustomDecoratedContainer(
                    text: "ابدأ الآن كزائر بدون حساب",
                    isDark: isDark,
                    onPressed: () =>
                        navigateAndFinish(context, HomeScreen()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
