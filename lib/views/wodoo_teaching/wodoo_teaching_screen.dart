import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/views/home/home_screen.dart';
import 'package:moshaf/views/pray_teaching/pray_instructions_screen.dart';
import 'package:moshaf/views/widgets/custom_outlined_green_button.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../widgets/custom_green_button.dart';

class WodooTeachingScreen extends StatefulWidget {
  const WodooTeachingScreen({super.key});

  @override
  State<WodooTeachingScreen> createState() => _WodooTeachingScreenState();
}

class _WodooTeachingScreenState extends State<WodooTeachingScreen> {
  int index = 0;

  List instructions = [
    {
      "title": "غسل الكفين :",
      "content": "تبدأ بغسل اليدين إلى الرسغين ثلاث مرات، حتى تتأكد من نظافة اليدين قبل لمس باقي الأعضاء."
    },
    {
      "title": "المضمضة :",
      "content": "تأخذ الماء بيدك اليمنى وتدخله في فمك، ثم تحركه داخل الفم وتخرجه، وتكرر ذلك ثلاث مرات."
    },
    {
      "title": "الاستنشاق والاستنثار :",
      "content": "تستنشق الماء بأنفك ثم تخرجه بالنفس، وتفعل هذا ثلاث مرات."
    },
    {
      "title": "غسل الوجه :",
      "content": "تغسل وجهك كاملًا بالماء من منبت الشعر حتى أسفل الذقن، ومن الأذن اليمنى إلى اليسرى."
    },
    {
      "title": "غسل اليدين إلى المرفقين :",
      "content": "تغسل اليد اليمنى من الأصابع إلى الكوع ثلاث مرات، ثم اليسرى."
    },
    {
      "title": "مسح الرأس :",
      "content": "تمسح رأسك مرة واحدة من الأمام للخلف ثم العودة للأمام."
    },
    {
      "title": "مسح الأذنين :",
      "content": "تمسح الأذنين بالماء المتبقي بيديك، داخل الأذن وخارجها مرة واحدة."
    },
    {
      "title": "غسل القدمين :",
      "content": "تغسل الرجل اليمنى ثم اليسرى ثلاث مرات مع التأكد من وصول الماء بين الأصابع."
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);

    // ===== GOLD MODE =====
    final gold = AppColors.isGoldMode;

    final bgClr = gold
        ? const Color(AppColors.goldBackground)
        : (isDark ? const Color(AppColors.scaffoldBg) : Colors.white);

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final highlightClr =
    gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen);

    final dotActive = highlightClr;
    final dotInactive = gold
        ? const Color(AppColors.goldBorder)
        : (isDark ? const Color(0xff3E3E3E) : const Color(0xffBFBFBF));

    return Scaffold(
      backgroundColor: bgClr,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // ========== HEADER ==========
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 20.0,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("تعليم الوضوء",
                        style: AppTextStyles.madReg16(
                          context,
                          color: textClr,
                        )),

                    if (index == 0 || index == instructions.length - 1)
                      InkWell(
                        onTap: () {
                          if (index == 0) {
                            setState(() => index = instructions.length - 1);
                          } else {
                            setState(() => index = 0);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                              vertical: 6, horizontal: 19),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(38),
                            border: Border.all(color: borderClr),
                          ),
                          child: Text(
                            index == 0 ? "تخطي" : "رجوع",
                            style:
                            AppTextStyles.madReg14(context, color: textClr),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 25.h),

              // ========== IMAGE BOX ==========
              Container(
                width: double.infinity,
                height: 200.h,
                padding: EdgeInsetsDirectional.only(
                    start: 120.w, end: 120.w, top: 60.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderClr),
                ),
                child: Image.asset("assets/images/wodoo${index + 1}.png"),
              ),

              const SizedBox(height: 8),

              // ========== TEXT BOX ==========
              Container(
                width: double.infinity,
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 17, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderClr),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "${instructions[index]["title"]}\n",
                        style: AppTextStyles.madB14(
                          context,
                          color: highlightClr,
                        ),
                      ),
                      TextSpan(
                        text: instructions[index]["content"],
                        style: AppTextStyles.madReg14(
                          context,
                          color: textClr,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ========== DOTS INDICATOR ==========
              SizedBox(
                height: 8,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, i) => i == index
                      ? Container(
                    width: 50,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotActive,
                      borderRadius: BorderRadius.circular(40),
                    ),
                  )
                      : Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotInactive,
                      shape: BoxShape.circle,
                    ),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: instructions.length,
                ),
              ),

              const SizedBox(height: 20),

              // ========== BUTTONS ==========
              index == 0
                  ? CustomGreenButton(
                text: "التالي",
                color: gold ? highlightClr : null,
                textColor: Colors.white,
                onTap: () {
                  setState(() => index++);
                },
              )
                  : Row(
                spacing: 8.w,
                children: [
                  Expanded(
                    child: CustomGreenButton(
                      text: index == instructions.length - 1
                          ? "تعلم الصلاة"
                          : "التالي",
                      color: gold ? highlightClr : null,
                      textColor:  Colors.white,
                      onTap: () {
                        if (index == instructions.length - 1) {
                          navigateAndFinish(
                              context, PrayInstructionsScreen());
                        } else {
                          setState(() => index++);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: CustomOutlinedGreenButton(
                      text: index == instructions.length - 1
                          ? "الرجوع للرئيسية"
                          : "السابق",
                      color: borderClr,
                      textStyle: AppTextStyles.madB14(
                        context,
                        color: textClr,
                      ),
                      onTap: () {
                        if (index == instructions.length - 1) {
                          navigateAndFinish(context, HomeScreen());
                        } else {
                          setState(() => index--);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
