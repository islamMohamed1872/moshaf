import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/views/home/home_screen.dart';
import 'package:moshaf/views/pray_teaching/pray_teaching_screen.dart';
import '../../components/components.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../widgets/custom_green_button.dart';

class PrayInstructionsScreen extends StatelessWidget {
  const PrayInstructionsScreen({super.key});

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

    return Scaffold(
      backgroundColor: bgClr,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ========= HEADER ==========
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
                      style:
                      AppTextStyles.madReg16(context, color: textClr),
                    ),
                    InkWell(
                      onTap: () => navigateAndFinish(context, HomeScreen()),
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                            vertical: 6, horizontal: 19),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(38),
                          border: Border.all(color: borderClr),
                        ),
                        child: Text(
                          "رجوع",
                          style:
                          AppTextStyles.madReg14(context, color: textClr),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10.h),

              // ========= INTRO TEXT BOX ==========
              Container(
                width: double.infinity,
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 17, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderClr),
                ),
                child: Text(
                  "الصلاة عمود الدين، ولا حظ في الإسلام لمن تركها، وهي صلة بين العبد وربه، فمن قطعها فقد قطع الصلة بينه وبين ربه وخالقه، ومن قطع هذه الصلة فقد خسر خسراناً مبيناً. والواجب على من ابتلي بترك الصلاة أو التقصير فيها أن يتوب إلى الله تعالى توبة صادقة نصوحا، وأن يتذكر أن ترك الصلاة سبب الويل والعذاب والنكد في الدنيا وفي الآخرة، وسبب لتسلط الشيطان الرجيم على العبد",
                  style:
                  AppTextStyles.madReg14(context, color: textClr),
                ),
              ),

              const SizedBox(height: 8),

              // ========= AYAT LIST ==========
              Column(
                children: [ "﴿وَأَقِيمُوا الصَّلَاةَ وَآتُوا الزَّكَاةَ وَارْكَعُوا مَعَ الرَّاكِعِينَ﴾", "﴿إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا﴾", "﴿أَقِمِ الصَّلَاةَ لِدُلُوكِ الشَّمْسِ إِلَىٰ غَسَقِ اللَّيْلِ وَقُرْآنَ الْفَجْرِ ۖ إِنَّ قُرْآنَ الْفَجْرِ كَانَ مَشْهُودًا﴾", "﴿إِنَّنِي أَنَا اللَّهُ لَا إِلَٰهَ إِلَّا أَنَا فَاعْبُدْنِي وَأَقِمِ الصَّلَاةَ لِذِكْرِي﴾", "﴿اتْلُ مَا أُوحِيَ إِلَيْكَ مِنَ الْكِتَابِ وَأَقِمِ الصَّلَاةَ ۖ إِنَّ الصَّلَاةَ تَنْهَىٰ عَنِ الْفَحْشَاءِ وَالْمُنكَرِ﴾", "﴿قَدْ أَفْلَحَ الْمُؤْمِنُونَ ⟐ الَّذِينَ هُمْ فِي صَلَاتِهِمْ خَاشِعُونَ﴾", ]
                    .map(
                      (aya) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                    const EdgeInsetsDirectional.symmetric(
                        horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderClr),
                    ),
                    child: Text(
                      aya,
                      style: AppTextStyles.madB14(
                        context,
                        color: highlightClr,
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),

              SizedBox(height: 20.h),

              // ========= BUTTON ==========
              CustomGreenButton(
                text: "تعليم الصلاة",
                color: gold ? highlightClr : null,
                textColor: Colors.white,
                onTap: () {
                  navigateTo(context, PrayTeachingScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
