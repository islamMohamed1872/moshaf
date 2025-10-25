import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/views/widgets/custom_green_button.dart';
import 'package:moshaf/views/widgets/header.dart';
import 'package:moshaf/views/wodoo_teaching/wodoo_teaching_screen.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';

class WodooInstructionsScreen extends StatelessWidget {
  const WodooInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    return Scaffold(
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("تعليم الوضوء",
                    style: AppTextStyles.madReg16(context,color: isDark?Colors.white:Colors.black),
                  ),
                  InkWell(
                    onTap: () async{
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsetsDirectional.symmetric(
                        vertical: 6,horizontal: 19
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(38),
                        border: Border.all(
                          color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders),
                        ),
                      ),
                      child: Text("رجوع",style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),),
                    ),
                  ),

                ],
              ),
            ),
            SizedBox(height: 10.h,),
            Container(
              width: double.infinity,
              padding: EdgeInsetsDirectional.symmetric(horizontal: 17, vertical: 12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders))),
              child: RichText(
                  text: TextSpan(children: [
                    TextSpan(text: "( إذا أراد الرجل الصلاة فليتوضأ ) وهذا ; لأن الوضوء مفتاح الصلاة قال صلى الله عليه وسلم :", style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),),
                    TextSpan(text: " { مفتاح الصلاة الطهور } ", style: AppTextStyles.madB14(context, color: Color(AppColors.mainGreen))),
                    TextSpan(
                        text:
                        "ومن أراد دخول بيت مغلق بدأ بطلب المفتاح ، وإنما فعل محمد رحمه الله ذلك اقتداء بكتاب الله - تعالى - فإنه إمام المتقين قال الله تعالى - :",
                        style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black)),
                    TextSpan(text: " { إذا قمتم إلى الصلاة فاغسلوا وجوهكم } ", style: AppTextStyles.madB14(context, color: Color(AppColors.mainGreen))),
                    TextSpan(text: "فاقتدى بالكتاب في البداية بالوضوء لهذا ، وفي ترك الاستثناء هاهنا وذكره في الحج كما قال الله - تعالى - :", style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black)),
                    TextSpan(text: " { لتدخلن المسجد الحرام إن شاء الله آمنين } ", style: AppTextStyles.madB14(context, color: Color(AppColors.mainGreen))),
                    TextSpan(text: "، وفي إضمار الحدث ، فإنه مضمر في الكتاب ومعنى قوله :", style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black)),
                    TextSpan(text: " { إذا قمتم إلى الصلاة } ", style: AppTextStyles.madB14(context, color: Color(AppColors.mainGreen))),
                    TextSpan(text: "من منامكم أو وأنتم محدثون هذا هو المذهب عند جمهور الفقهاء رحمهم الله ، فأما على قول أصحاب الظواهر فلا إضمار في الآية", style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black)),

                  ])),
            ),
            const SizedBox(height: 8,),
            Container(
              width: double.infinity,
              padding: EdgeInsetsDirectional.symmetric(horizontal: 17, vertical: 12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders))),
              child: RichText(
                  text: TextSpan(children: [
                    TextSpan(text: "والوضوء فرض سببه القيام إلى الصلاة فكل من قام إليها فعليه أن يتوضأ وهذا فاسد لما روي :", style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black)),
                    TextSpan(text: " { أن النبي صلى الله عليه وسلم كان يتوضأ لكل صلاة فلما كان يوم الفتح أو يوم الخندق صلى الخمس بوضوء واحد فقال له عمر رضي الله عنه رأيتك اليوم تفعل شيئا لم تكن تفعله من قبل . فقال : عمدا فعلت يا عمر كي لا تحرجوا } ", style: AppTextStyles.madB14(context, color: Color(AppColors.mainGreen))),
                    TextSpan(
                        text:
                        "ومن أراد دخول بيت مغلق بدأ بطلب المفتاح ، وإنما فعل محمد رحمه الله ذلك اقتداء بكتاب الله - تعالى - فإنه إمام المتقين قال الله تعالى - :",
                        style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black)),
                    TextSpan(text: "فقياس مذهبهم يوجب أن من جلس فتوضأ ثم قام إلى الصلاة يلزمه وضوء آخر ، فلا يزال كذلك مشغولا بالوضوء لا يتفرغ للصلاة ، وفساد هذا لا يخفى على أحد", style: AppTextStyles.madB14(context, color: Color(AppColors.mainGreen))),
                  ])),
            ),
            const Spacer(),
            CustomGreenButton(text: "تعليم الوضوء", onTap: () {
              navigateTo(context, WodooTeachingScreen());
            },)
          ],
        ),
      )),
    );
  }
}
