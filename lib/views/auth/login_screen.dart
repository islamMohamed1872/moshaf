import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/auth/auth_cubit.dart';
import 'package:moshaf/controllers/auth/auth_states.dart';
import 'package:moshaf/views/auth/forget_password_screen.dart';
import 'package:moshaf/views/auth/register_screen.dart';
import 'package:moshaf/views/home/home_screen.dart';
import 'package:moshaf/views/widgets/custom_green_button.dart';
import 'package:moshaf/views/widgets/header.dart';
import 'dart:io';
import '../../controllers/theme/theme_cubit.dart';
import '../landing/widgets/custom_decorated_container.dart';
import '../widgets/custom_text_form_field.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);

    // 🌟 Gold mode colors
    final borderColor = AppColors.getBorderColor(isDark: isDark);
    final textColor = AppColors.getTextColor(isDark: isDark);
    final primaryColor = AppColors.getPrimaryColor();
    final bgColor = AppColors.getBackgroundColor(isDark: isDark);

    return BlocConsumer<AuthCubit, AuthStates>(
      builder: (context, state) {
        final cubit = AuthCubit.get(context);

        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: bgColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Form(
                key: loginFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Header(
                      title: "تسجيل الدخول",
                      isDark: isDark,
                      onTap: () {
                        cubit.clearControllers();
                        Navigator.pop(context);
                      },
                      iconColor: textColor,
                    ),

                    SizedBox(height: 40.h),

                    Text(
                      "البريد الالكتروني",
                      style: AppTextStyles.madReg14(context, color: textColor),
                    ),

                    SizedBox(height: 15),

                    // EMAIL FIELD
                    CustomTextField(
                      controller: cubit.emailController,
                      hintText: "info@gmail.com",
                      keyboardType: TextInputType.emailAddress,
                      isDark: isDark,
                      validator: (value) =>
                      value == null || value.isEmpty ? "مطلوب" : null,
                    ),

                    SizedBox(height: 25),

                    Text(
                      "كلمة المرور",
                      style: AppTextStyles.madReg14(context, color: textColor),
                    ),

                    SizedBox(height: 15),

                    // PASSWORD FIELD
                    CustomTextField(
                      controller: cubit.passwordController,
                      hintText: "ادخل كلمة المرور",
                      obscureText: cubit.isPasswordHidden,
                      suffixIcon: cubit.isPasswordHidden
                          ? Icons.visibility
                          : Icons.visibility_off,
                      isDark: isDark,
                      onSuffixPressed: cubit.togglePasswordVisibility,
                      validator: (value) =>
                      value == null || value.isEmpty ? "مطلوب" : null,
                    ),

                    SizedBox(height: 8),

                    Row(
                      children: [
                        Spacer(),
                        InkWell(
                          onTap: () {
                            navigateTo(context, ForgetPasswordScreen());
                          },
                          child: Text(
                            "نسيت كلمة المرور؟",
                            style: AppTextStyles.madReg12(
                              context,
                              color: textColor,
                            ),
                          ),
                        )
                      ],
                    ),

                    SizedBox(height: 25.h),

                    // LOGIN BUTTON
                    ConditionalBuilder(
                      condition: state
                      is! AuthLoginWithEmailAndPasswordLoadingState,
                      builder: (context) => CustomGreenButton(
                        text: "تسجيل الدخول",
                        verticalPadding: 15,
                        onTap: () {
                          if (loginFormKey.currentState!.validate()) {
                            cubit.loginWithEmailAndPassword(
                              email: cubit.emailController.text,
                              password: cubit.passwordController.text,
                            );
                          }
                        },
                        color: AppColors.isGoldMode?primaryColor:null ,
                      ),
                      fallback: (context) => Center(
                        child: CircularProgressIndicator(
                          color: primaryColor,
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.0.h),
                      child: Divider(color: borderColor),
                    ),

                    // GOOGLE SIGN IN
                    CustomDecoratedContainer(
                      imagePath: isDark
                          ? "assets/images/google.png"
                          : "assets/images/light_google.png",
                      text: "تسجيل الدخول باستخدام جوجل",
                      isDark: isDark,
                      onPressed: cubit.signInWithGoogle,
                    ),

                    if (Platform.isIOS) SizedBox(height: 20.h),

                    if (Platform.isIOS)
                      CustomDecoratedContainer(
                        imagePath: isDark
                            ? "assets/images/apple.png"
                            : "assets/images/light_apple.png",
                        text: "تسجيل الدخول باستخدام ابل",
                        isDark: isDark,
                        onPressed: () {},
                      ),

                    Spacer(),

                    InkWell(
                      onTap: () {
                        cubit.clearControllers();
                        navigateTo(context, RegisterScreen());
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "ليس لديك حساب؟",
                            style: AppTextStyles.madReg12(
                              context,
                              color: borderColor,
                            ),
                          ),
                          Text(
                            " سجل الان",
                            style:
                            AppTextStyles.madReg12(context, color: textColor),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
      listener: (context, state) {
        if (state is AuthLoginWithEmailAndPasswordSuccessState ||
            state is AuthSignInWithGoogleSuccessState ||
            state is AuthSignInWithAppleSuccessState) {
          AuthCubit.get(context).clearControllers();
          navigateAndFinish(context, HomeScreen());
        }

        if (state is AuthLoginWithEmailAndPasswordErrorState) {
          Fluttertoast.showToast(
            msg: state.errorMessage,
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            gravity: ToastGravity.BOTTOM,
          );
        }
      },
    );
  }
}
