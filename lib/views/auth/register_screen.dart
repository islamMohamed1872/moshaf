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

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    return BlocConsumer<AuthCubit,AuthStates>(
        builder: (context, state) {
          final cubit = AuthCubit.get(context);
          return Scaffold(
            resizeToAvoidBottomInset: true,
              body: SafeArea(child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Form(
                  key: loginFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Header(title: "تسجيل", isDark: isDark,onTap: () {
                          cubit.clearControllers();
                          Navigator.pop(context);
                        },
                          iconColor: isDark?Colors.white:Colors.black,
                        ),
                        SizedBox(height: 40.h,),
                        Text("البريد الالكتروني",
                        style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),
                        ),
                        SizedBox(height: 15,),
                        CustomTextField(
                          controller: cubit.emailController,
                          hintText: "info@gmail.com",
                          keyboardType: TextInputType.emailAddress,
                          isDark: isDark,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "مطلوب";
                            }
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

                            if (!emailRegex.hasMatch(value)) {
                              return "البريد الإلكتروني غير صالح";
                            }

                            return null;
                          },
                        ),
                        SizedBox(height: 25,),
                        Text("كلمة المرور",
                          style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),
                        ),
                        SizedBox(height: 15,),
                        CustomTextField(
                          controller: cubit.passwordController,
                          hintText: "ادخل كلمة المرور",
                          obscureText: cubit.isPasswordHidden,
                          suffixIcon:
                          cubit.isPasswordHidden ? Icons.visibility : Icons.visibility_off,
                          keyboardType: TextInputType.text,
                          isDark: isDark,
                          onSuffixPressed: () {
                            cubit.togglePasswordVisibility();
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "مطلوب";
                            }
                            else if(cubit.passwordController.text!=cubit.confirmPasswordController.text){
                              return "كلمتا المرور غير متطابقتين";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 25,),
                        Text("تأكيد كلمة المرور",
                          style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),
                        ),
                        SizedBox(height: 15,),
                        CustomTextField(
                          controller: cubit.confirmPasswordController,
                          hintText: "تأكيد كلمة المرور",
                          obscureText: cubit.isPasswordHidden,
                          suffixIcon:
                          cubit.isPasswordHidden ? Icons.visibility : Icons.visibility_off,
                          keyboardType: TextInputType.text,
                          isDark: isDark,
                          onSuffixPressed: () {
                            cubit.togglePasswordVisibility();
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "مطلوب";
                            }
                            else if(cubit.passwordController.text!=cubit.confirmPasswordController.text){
                              return "كلمتا المرور غير متطابقتين";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 8,),
                        Row(
                          children: [
                            const Spacer(),
                            InkWell(
                              onTap: (){
                    
                              },
                              child: Text(
                                "نسيت كلمة المرور؟",
                                style: AppTextStyles.madReg12(context,color: Color(isDark?AppColors.containerDarkBorders:0xff4F4F4F)),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 25.h,),
                        ConditionalBuilder(condition: state is !RegisterWithEmailAndPasswordLoadingState,
                            builder: (context) => CustomGreenButton(
                              text: "تسجيل", onTap: () {
                              if (loginFormKey.currentState!.validate()) {
                                cubit.registerWithEmailAndPassword(email: cubit.emailController.text, password: cubit.passwordController.text);
                              }
                    
                            },
                              verticalPadding: 15,
                            ), 
                            fallback: (context) => Center(
                              child: CircularProgressIndicator(
                                color: Color(AppColors.mainGreen),
                              ),
                            ),),
                        Padding(
                          padding: EdgeInsetsDirectional.symmetric(vertical: 30.0.h),
                          child: Divider(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders),),
                        ),
                        CustomDecoratedContainer(
                            imagePath:isDark? "assets/images/google.png":"assets/images/light_google.png",
                            text: "تسجيل الدخول باستخدام جوجل",
                            isDark: isDark,
                            onPressed: (){
                              cubit.signInWithGoogle();
                            }),
                        if(Platform.isIOS)
                        SizedBox(
                          height: 20.h,
                        ),
                        if(Platform.isIOS)
                        CustomDecoratedContainer(
                            imagePath:isDark? "assets/images/apple.png":"assets/images/light_apple.png",
                            text: "تسجيل الدخول باستخدام ابل",
                            isDark: isDark,
                            onPressed: (){
                    
                            }),
                        SizedBox(
                          height: 20.h,
                        ),
                        InkWell(
                          onTap: (){
                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("لدي حساب؟",
                                style: AppTextStyles.madReg12(context,color: Color(isDark?AppColors.containerDarkBorders:0xff4F4F4F)),
                              ),
                              Text(" تسجيل الدخول",
                                style: AppTextStyles.madReg12(context,color: isDark?Colors.white:Colors.black),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )),
          );
        },
      listener: (context, state) {
        if(state is RegisterWithEmailAndPasswordSuccessState){
          AuthCubit.get(context).clearControllers();
          Fluttertoast.showToast(
            msg: "تم تسجيل الحساب بنجاح",
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor:isDark?Colors.white:Colors.black,
            textColor: isDark?Colors.black:Colors.white,
            gravity: ToastGravity.BOTTOM,
            fontSize: 16.0,
          );
          Navigator.pop(context);
        }
        else if (state is AuthSignInWithGoogleSuccessState||state is AuthSignInWithAppleSuccessState) {
          navigateAndFinish(context, HomeScreen());
        }
        else if (state is RegisterWithEmailAndPasswordErrorState) {
          Fluttertoast.showToast(
            msg: state.errorMessage,
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            gravity: ToastGravity.BOTTOM,
            fontSize: 16.0,
          );
        }
      },
    );
  }
}
