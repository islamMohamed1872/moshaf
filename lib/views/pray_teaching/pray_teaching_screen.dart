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

class PrayTeachingScreen extends StatefulWidget {
  const PrayTeachingScreen({super.key});

  @override
  State<PrayTeachingScreen> createState() => _PrayTeachingScreenState();
}

class _PrayTeachingScreenState extends State<PrayTeachingScreen> {
  int index = 0;

  List instructions = [
    {
      "title": "النية والتكبير :",
      "content":
      '''تستحضر النية في قلبك أنك ستصلي (مثلاً: صلاة الفجر أو الظهر...)، ثم ترفع يديك وتقول "الله أكبر".'''
    },
    {
      "title": "قراءة الفاتحة وسورة قصيرة :",
      "content":
      "تضع يدك اليمنى على اليسرى فوق صدرك، وتقرأ سورة الفاتحة، ثم تقرأ ما تيسر من القرآن بعدها."
    },
    {
      "title": "الركوع :",
      "content":
      "تكبر وتركع، واضعًا يديك على ركبتيك وظهرك مستقيم، وتقول \"سبحان ربي العظيم\" ثلاث مرات."
    },
    {
      "title": "الرفع من الركوع :",
      "content": '''ترفع وتقول: "سمع الله لمن حمده" ثم تقول "ربنا ولك الحمد".'''
    },
    {
      "title": "السجود الأول :",
      "content":
      '''تنزل ساجدًا على سبعة أعضاء: الجبهة والأنف، اليدين، الركبتين، وأطراف القدمين، وتقول "سبحان ربي الأعلى" ثلاث مرات.'''
    },
    {
      "title": "الجلوس بين السجدتين :",
      "content":
      '''ترفع من السجود وتجلس على رجلك اليسرى، وتقول: "رب اغفر لي، رب اغفر لي".'''
    },
    {
      "title": "السجود الثاني :",
      "content": "تسجد مرة أخرى مثل الأولى. (وهكذا تكون انتهيت من ركعة)."
    },
    {
      "title": "التشهد والجلوس الأخير :",
      "content":
      "في آخر ركعة تجلس وتقرأ التشهد والصلاة الإبراهيمية ... ثم تسلم يمينًا ويسارًا."
    },
    {
      "title": "التسليم :",
      "content":
      '''تميل برأسك يمينًا وتقول "السلام عليكم ورحمة الله"، ثم شمالًا وتكررها، وبذلك تنتهي الصلاة.'''
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

    final accentClr =
    gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen);

    final indicatorInactive = gold
        ? const Color(0xFF806A30)
        : (isDark ? const Color(0xff3E3E3E) : const Color(0xffBFBFBF));

    return Scaffold(
      backgroundColor: bgClr,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ================= HEADER ================
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 20.0,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "تعليم الصلاة",
                      style: AppTextStyles.madReg16(context, color: textClr),
                    ),

                    // Skip / Back button
                    if (index == 0 || index == instructions.length - 1)
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (index == 0) {
                              index = instructions.length - 1;
                            } else {
                              index = 0;
                            }
                          });
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
                            style: AppTextStyles.madReg14(context,
                                color: textClr),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 25.h),

              // ========== PRAYING IMAGE BOX ===========
              Container(
                width: double.infinity,
                height: 200.h,
                padding: EdgeInsetsDirectional.only(
                    start: 120.w, end: 120.w, top: 60.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderClr),
                ),
                child: Image.asset("assets/images/praying${index + 1}.png"),
              ),

              const SizedBox(height: 8),

              // ========== TEXT BOX ===========
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
                        style: AppTextStyles.madB14(context, color: accentClr),
                      ),
                      TextSpan(
                        text: "${instructions[index]["content"]}",
                        style: AppTextStyles.madReg14(context, color: textClr),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ========== STEPPER INDICATOR ===========
              Center(
                child: SizedBox(
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
                        color: accentClr,
                        borderRadius: BorderRadius.circular(40),
                      ),
                    )
                        : Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: indicatorInactive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    separatorBuilder: (context, _) =>
                    const SizedBox(width: 8),
                    itemCount: instructions.length,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ============ BUTTONS ============
              index == 0 || index == instructions.length - 1
                  ? CustomGreenButton(
                text: index == 0 ? "التالي" : "الذهاب للرئيسية",
                color: gold ? accentClr : null,
                textColor:  Colors.white,
                onTap: () {
                  if (index == 0) {
                    setState(() => index++);
                  } else {
                    navigateAndFinish(context, HomeScreen());
                  }
                },
              )
                  : Row(
                children: [
                  Expanded(
                    child: CustomGreenButton(
                      text: index == instructions.length - 1
                          ? "تعلم الصلاة"
                          : "التالي",
                      color: gold ? accentClr : null,
                      textColor: Colors.white,
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
                  SizedBox(width: 8.w),
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
                          Navigator.pop(context);
                        } else if (index > 0) {
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
