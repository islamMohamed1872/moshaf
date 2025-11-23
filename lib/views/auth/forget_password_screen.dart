import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/auth/auth_cubit.dart';
import 'package:moshaf/controllers/auth/auth_states.dart';
import 'package:moshaf/views/widgets/custom_green_button.dart';
import 'package:moshaf/views/widgets/custom_text_form_field.dart';
import 'package:moshaf/views/widgets/header.dart';

import '../../controllers/theme/theme_cubit.dart';

class ForgetPasswordScreen extends StatelessWidget {
  ForgetPasswordScreen({super.key});

  final GlobalKey<FormState> forgetKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);

    final borderColor = AppColors.getBorderColor(isDark: isDark);
    final textColor = AppColors.getTextColor(isDark: isDark);
    final bgColor = AppColors.getBackgroundColor(isDark: isDark);

    final cubit = AuthCubit.get(context);

    return BlocConsumer<AuthCubit, AuthStates>(
      listener: (context, state) {
        if (state is AuthForgetPasswordSuccessState) {
          Fluttertoast.showToast(
            msg: "تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك.\nيرجى التحقق من صندوق الوارد أو مجلد الرسائل غير المرغوب فيها (Spam).",
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
            gravity: ToastGravity.BOTTOM,
          );

          Navigator.pop(context);
        }

        if (state is AuthForgetPasswordErrorState) {
          Fluttertoast.showToast(
            msg: state.errorMessage,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(15.w),
              child: Form(
                key: forgetKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Header(
                      title: "نسيت كلمة المرور",
                      isDark: isDark,
                      onTap: () => Navigator.pop(context),
                      iconColor: textColor,
                    ),

                    SizedBox(height: 40.h),

                    Text(
                      "البريد الالكتروني",
                      style: AppTextStyles.madReg14(context, color: textColor),
                    ),
                    SizedBox(height: 15.h),

                    CustomTextField(
                      controller: cubit.emailController,
                      hintText: "example@gmail.com",
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "البريد الإلكتروني مطلوب";
                        }
                        final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return "البريد الإلكتروني غير صالح";
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 35.h),

                    state is AuthForgetPasswordLoadingState
                        ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.getPrimaryColor(),
                      ),
                    )
                        : CustomGreenButton(
                      text: "إرسال رابط إعادة التعيين",
                      verticalPadding: 15,
                      onTap: () {
                        if (forgetKey.currentState!.validate()) {
                          cubit.sendPasswordReset(
                            cubit.emailController.text.trim(),
                          );
                        }
                      },
                      color: AppColors.isGoldMode?Color(AppColors.goldPrimary):null,
                    ),

                    SizedBox(height: 20.h),

                  Center(
                    child: Text(
                      "سنرسل لك رابطًا لإعادة تعيين كلمة المرور.\nيرجى التحقق من صندوق الوارد أو مجلد الرسائل غير المرغوب فيها (Spam).",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.madReg12(
                        context,
                        color: textColor,
                      ),
                    ),
              ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
