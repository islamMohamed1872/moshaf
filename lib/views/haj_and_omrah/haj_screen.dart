import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/views/haj_and_omrah/omrah_screen.dart';
import 'package:moshaf/views/home/home_screen.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';

class HajScreen extends StatelessWidget {
  final bool isDark;
  const HajScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.isGoldMode;

    final borderColor = AppColors.getBorderColor(isDark: isDark);
    final textColor = AppColors.getTextColor(isDark: isDark);
    final bgColor = AppColors.getBackgroundColor(isDark: isDark);
    final primaryColor = AppColors.getPrimaryColor();

    final List steps = [
      {"title": "الإحرام:", "step": " نية الدخول في النسك ولبس ملابس الإحرام والتلبية"},
      {"title": "الطواف:", "step": " لطواف سبعة أشواط حول الكعبة"},
      {"title": "السعي:", "step": " السعي بين الصفا والمروة سبعة أشواط"},
      {"title": "المبيت بمنى", "step": " يوم التروية (8 ذي الحجة)."},
      {"title": "الوقوف بعرفة:", "step": " من زوال الشمس حتى غروبها (9 ذي الحجة)"},
      {"title": "المبيت بمزدلفة:", "step": " بعد الإفاضة من عرفة إلى الفجر"},
      {"title": "رمي جمرة العقبة الكبرى:", "step": " يوم العيد (10 ذي الحجة)"},
      {"title": "ذبح الهدي:", "step": " واجب على المتمتع والقارن"},
      {"title": "الحلق أو التقصير:", "step": " الحلق أفضل للرجال، والتقصير للنساء"},
      {"title": "طواف الإفاضة:", "step": " ركن أساسي من الحج"},
      {
        "title": "المبيت بمنى:",
        "step": " في أيام التشريق (11 و12 و13 ذي الحجة) مع رمي الجمرات الثلاث كل يوم."
      },
      {"title": "طواف الوداع:", "step": " آخر نسك يفعله الحاج قبل مغادرة مكة"},
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  "assets/images/haj_and_omrah.png",
                  height: 220.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                /// Gradient
                Container(
                  width: double.infinity,
                  height: 220.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        gold
                            ? const Color(AppColors.goldPrimary)
                            .withValues(alpha: 0)
                            : Colors.black.withValues(alpha: 0),
                        bgColor,
                      ],
                    ),
                  ),
                ),

                /// Back Button
                Positioned(
                  top: 15,
                  left: 20,
                  child: InkWell(
                    onTap: () => navigateAndFinish(context, HomeScreen()),
                    child: Container(
                      width: 30.w,
                      height: 30.w,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                      ),
                      child: FittedBox(
                        child: Icon(
                          context.locale.languageCode == "ar"
                              ? Icons.arrow_forward_ios
                              : Icons.arrow_back_ios,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),

                /// Ayah
                Positioned(
                  right: 10,
                  left: 10,
                  child: Text(
                    "وَأَتِموا الْحَجَّ وَالْعُمْرَةَ لِلَّهِ",
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.kufi24(context, color: Colors.white),
                  ),
                ),

                /// Tabs (Hajj active)
                Positioned(
                  bottom: 0,
                  child: Row(
                    children: [
                      /// Umrah
                      InkWell(
                        onTap: () => navigateAndFinish(
                            context, OmrahScreen(isDark: isDark)),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9.w, vertical: 3.h),
                          child: Text(
                            "العمرة",
                            style:
                            AppTextStyles.madMd12(context, color: textColor),
                          ),
                        ),
                      ),

                      /// Hajj (active)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 9.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(45),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          "الحج",
                          style:
                          AppTextStyles.madMd12(context, color: textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            /// Divider
            Container(
              width: double.infinity,
              height: 1,
              margin: EdgeInsets.symmetric(vertical: 10),
              color: borderColor,
            ),

            /// Steps
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 14),
                itemCount: steps.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (context, index) => Container(
                  padding:
                  EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: steps[index]['title'],
                          style: AppTextStyles.madB14(
                            context,
                            color: primaryColor,
                          ),
                        ),
                        TextSpan(
                          text: steps[index]['step'],
                          style: AppTextStyles.madReg14(
                            context,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
