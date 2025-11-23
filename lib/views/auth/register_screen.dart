import 'dart:io';

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
import 'package:moshaf/views/home/home_screen.dart';
import 'package:moshaf/views/widgets/custom_green_button.dart';
import 'package:moshaf/views/widgets/header.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../landing/widgets/custom_decorated_container.dart';
import '../widgets/custom_text_form_field.dart';
import 'forget_password_screen.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);

    // GOLD MODE COLORS
    final borderColor = AppColors.getBorderColor(isDark: isDark);
    final textColor = AppColors.getTextColor(isDark: isDark);
    final bgColor = AppColors.getBackgroundColor(isDark: isDark);
    final primaryColor = AppColors.getPrimaryColor();

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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 🔙 HEADER
                      Header(
                        title: "تسجيل",
                        isDark: isDark,
                        onTap: () {
                          cubit.clearControllers();
                          Navigator.pop(context);
                        },
                        iconColor: textColor,
                      ),

                      SizedBox(height: 40.h),

                      // 📧 EMAIL SECTION
                      Text(
                        "البريد الالكتروني",
                        style: AppTextStyles.madReg14(context, color: textColor),
                      ),
                      SizedBox(height: 15.h),

                      CustomTextField(
                        controller: cubit.emailController,
                        hintText: "info@gmail.com",
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "مطلوب";

                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) return "البريد الإلكتروني غير صالح";

                          return null;
                        },
                      ),

                      SizedBox(height: 25.h),

                      // 🔐 PASSWORD
                      Text("كلمة المرور",
                          style: AppTextStyles.madReg14(context, color: textColor)),
                      SizedBox(height: 15.h),

                      CustomTextField(
                        controller: cubit.passwordController,
                        hintText: "ادخل كلمة المرور",
                        obscureText: cubit.isPasswordHidden,
                        suffixIcon: cubit.isPasswordHidden
                            ? Icons.visibility
                            : Icons.visibility_off,
                        keyboardType: TextInputType.text,
                        isDark: isDark,
                        onSuffixPressed: cubit.togglePasswordVisibility,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "مطلوب";

                          if (cubit.passwordController.text !=
                              cubit.confirmPasswordController.text) {
                            return "كلمتا المرور غير متطابقتين";
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 25.h),

                      // 🔐 CONFIRM PASSWORD
                      Text(
                        "تأكيد كلمة المرور",
                        style: AppTextStyles.madReg14(context, color: textColor),
                      ),
                      SizedBox(height: 15.h),

                      CustomTextField(
                        controller: cubit.confirmPasswordController,
                        hintText: "تأكيد كلمة المرور",
                        obscureText: cubit.isPasswordHidden,
                        suffixIcon: cubit.isPasswordHidden
                            ? Icons.visibility
                            : Icons.visibility_off,
                        keyboardType: TextInputType.text,
                        isDark: isDark,
                        onSuffixPressed: cubit.togglePasswordVisibility,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "مطلوب";

                          if (cubit.passwordController.text !=
                              cubit.confirmPasswordController.text) {
                            return "كلمتا المرور غير متطابقتين";
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 8.h),

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
                          ),
                        ],
                      ),

                      SizedBox(height: 25.h),

                      // 🟩 REGISTER BUTTON
                      ConditionalBuilder(
                        condition:
                        state is! RegisterWithEmailAndPasswordLoadingState,
                        builder: (context) => CustomGreenButton(
                          text: "تسجيل",
                          verticalPadding: 15,
                          onTap: () {
                            if (loginFormKey.currentState!.validate()) {
                              cubit.registerWithEmailAndPassword(
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
                        padding:
                        EdgeInsets.symmetric(vertical: 30.0.h),
                        child: Divider(color: borderColor),
                      ),

                      // 🌐 GOOGLE SIGN IN
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

                      SizedBox(height: 20.h),

                      // 🔁 BACK TO LOGIN
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "لدي حساب؟",
                              style: AppTextStyles.madReg12(
                                  context, color: borderColor),
                            ),
                            Text(
                              " تسجيل الدخول",
                              style:
                              AppTextStyles.madReg12(context, color: textColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      listener: (context, state) {
        final isDark = context.read<ThemeCubit>().isDark;

        if (state is RegisterWithEmailAndPasswordSuccessState) {
          AuthCubit.get(context).clearControllers();

          Fluttertoast.showToast(
            msg: "تم تسجيل الحساب بنجاح",
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: isDark ? Colors.white : Colors.black,
            textColor: isDark ? Colors.black : Colors.white,
            gravity: ToastGravity.BOTTOM,
          );

          Navigator.pop(context);
        }

        else if (state is AuthSignInWithGoogleSuccessState ||
            state is AuthSignInWithAppleSuccessState) {
          navigateAndFinish(context, HomeScreen());
        }

        else if (state is RegisterWithEmailAndPasswordErrorState) {
          Fluttertoast.showToast(
            msg: state.errorMessage,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            gravity: ToastGravity.BOTTOM,
          );
        }
      },
    );
  }
}
