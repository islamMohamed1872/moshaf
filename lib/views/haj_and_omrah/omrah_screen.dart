import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/views/haj_and_omrah/haj_screen.dart';
import 'package:moshaf/views/home/home_screen.dart';

import '../../components/components.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';

class OmrahScreen extends StatelessWidget {
  final bool isDark;
  const OmrahScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.isGoldMode;

    final borderColor = AppColors.getBorderColor(isDark: isDark);
    final textColor = AppColors.getTextColor(isDark: isDark);
    final bgColor = AppColors.getBackgroundColor(isDark: isDark);
    final primaryColor = AppColors.getPrimaryColor();

    final List steps = [
      {
        "title": "الإحرام:",
        "step": " نية الدخول في النسك ولبس ملابس الإحرام والتلبية"
      },
      {
        "title": "الطواف:",
        "step": " الطواف سبعة أشواط حول الكعبة"
      },
      {
        "title": "السعي:",
        "step": " السعي بين الصفا والمروة سبعة أشواط"
      },
      {
        "title": "الحلق أو التقصير",
        "step": " الحلق أفضل للرجال، والتقصير للنساء"
      },
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

                /// Gradient overlay
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

                /// Back button
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

                /// Title Text
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

                /// Tabs (عمرة - حج)
                Positioned(
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Active (عمرة)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 9.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(45),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          "العمرة",
                          style: AppTextStyles.madMd12(context,
                              color: textColor),
                        ),
                      ),

                      /// Switch to حج
                      InkWell(
                        onTap: () => navigateAndFinish(
                            context, HajScreen(isDark: isDark)),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9.w, vertical: 3.h),
                          child: Text(
                            "الحج",
                            style: AppTextStyles.madMd12(context,
                                color: textColor),
                          ),
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
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
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
