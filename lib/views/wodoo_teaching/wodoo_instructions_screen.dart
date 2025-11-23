import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/views/widgets/custom_green_button.dart';
import 'package:moshaf/views/wodoo_teaching/wodoo_teaching_screen.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';

class WodooInstructionsScreen extends StatelessWidget {
  const WodooInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);

    // 🔹 GOLD MODE
    final gold = AppColors.isGoldMode;

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final highlightClr =
    gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen);

    final bgClr = gold
        ? const Color(AppColors.goldBackground)
        : (isDark ? Color(AppColors.scaffoldBg) : Colors.white);

    return Scaffold(
      backgroundColor: bgClr,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              // ======================= HEADER ==========================
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 20.0,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "تعليم الوضوء",
                      style: AppTextStyles.madReg16(
                        context,
                        color: textClr,
                      ),
                    ),

                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsetsDirectional.symmetric(
                            vertical: 6, horizontal: 19),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(38),
                          border: Border.all(color: borderClr),
                        ),
                        child: Text(
                          "رجوع",
                          style: AppTextStyles.madReg14(
                            context,
                            color: textClr,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10.h),

              // ================== FIRST PARAGRAPH =====================
              _instructionBox(
                context,
                isDark,
                borderClr,
                textClr,
                highlightClr,
                [
                  "( إذا أراد الرجل الصلاة فليتوضأ ) وهذا ; لأن الوضوء مفتاح الصلاة قال صلى الله عليه وسلم : ",
                  "{ مفتاح الصلاة الطهور }",
                  " ومن أراد دخول بيت مغلق بدأ بطلب المفتاح ، وإنما فعل محمد رحمه الله ذلك اقتداء بكتاب الله - تعالى - فإنه إمام المتقين قال الله تعالى - :",
                  "{ إذا قمتم إلى الصلاة فاغسلوا وجوهكم }",
                  " فاقتدى بالكتاب في البداية بالوضوء لهذا ، وفي ترك الاستثناء هاهنا وذكره في الحج كما قال الله - تعالى - :",
                  "{ لتدخلن المسجد الحرام إن شاء الله آمنين }",
                  " ، وفي إضمار الحدث ، فإنه مضمر في الكتاب ومعنى قوله : ",
                  "{ إذا قمتم إلى الصلاة }",
                  " من منامكم أو وأنتم محدثون هذا هو المذهب عند جمهور الفقهاء رحمهم الله ، فأما على قول أصحاب الظواهر فلا إضمار في الآية"
                ],
              ),

              const SizedBox(height: 8),

              // ================== SECOND PARAGRAPH =====================
              _instructionBox(
                context,
                isDark,
                borderClr,
                textClr,
                highlightClr,
                [
                  "والوضوء فرض سببه القيام إلى الصلاة فكل من قام إليها فعليه أن يتوضأ وهذا فاسد لما روي : ",
                  "{ أن النبي صلى الله عليه وسلم كان يتوضأ لكل صلاة فلما كان يوم الفتح أو يوم الخندق صلى الخمس بوضوء واحد فقال له عمر رضي الله عنه رأيتك اليوم تفعل شيئا لم تكن تفعله من قبل . فقال : عمدا فعلت يا عمر كي لا تحرجوا }",
                  " ومن أراد دخول بيت مغلق بدأ بطلب المفتاح ، وإنما فعل محمد رحمه الله ذلك اقتداء بكتاب الله - تعالى - فإنه إمام المتقين قال الله تعالى - :",
                  " فقياس مذهبهم يوجب أن من جلس فتوضأ ثم قام إلى الصلاة يلزمه وضوء آخر ، فلا يزال كذلك مشغولا بالوضوء لا يتفرغ للصلاة ، وفساد هذا لا يخفى على أحد",
                ],
              ),

              const Spacer(),

              // ================== BUTTON =====================
              CustomGreenButton(
                text: "تعليم الوضوء",
                textColor:  Colors.white,
                color: gold ? const Color(AppColors.goldPrimary) : null,
                onTap: () {
                  navigateTo(context, WodooTeachingScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================== REUSABLE WIDGEt ==========================
  Widget _instructionBox(
      BuildContext context,
      bool isDark,
      Color borderClr,
      Color textClr,
      Color highlightClr,
      List<String> segments,
      ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 17, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderClr),
      ),
      child: RichText(
        text: TextSpan(
          children: segments.map((seg) {
            final bool isHighlight = seg.startsWith("{") && seg.endsWith("}");
            final clean = isHighlight ? seg.replaceAll("{", "").replaceAll("}", "") : seg;

            return TextSpan(
              text: clean,
              style: isHighlight
                  ? AppTextStyles.madB14(context, color: highlightClr)
                  : AppTextStyles.madReg14(context, color: textClr),
            );
          }).toList(),
        ),
      ),
    );
  }
}
