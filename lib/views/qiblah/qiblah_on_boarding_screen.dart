import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/views/qiblah/qiblah_screen.dart';

import '../../constants/app_colors.dart';

class QiblahOnBoardingScreen extends StatelessWidget {
  const QiblahOnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                margin: EdgeInsetsDirectional.only(end: 20),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 15,vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Color(AppColors.containerBorders)),
                ),
                child: Text("تخطي",
                style: AppTextStyles.madReg14(context),
                ),
              ),
            ),
            SizedBox(
              height: 70.h,
            ),
            Image.asset("assets/images/kaabah.png"),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 19,vertical: 26),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Color(0xff3E3E3E).withValues(alpha: 0.8),
              ),
              child:  Column(
                spacing: 10.h,
                children: [

                  Text("تحديد القبلة",
                    style: AppTextStyles.madB20(context),
                  ),
                  Text("قَدْ نَرَى تَقَلُّبَ وَجْهِكَ فِي السَّمَاءِ فَلَنُوَلِّيَنَّكَ قِبْلَةً تَرْضَاهَا فَوَلِّ وَجْهَكَ شَطْرَ الْمَسْجِدِ الْحَرَامِ وَحَيْثُ مَا كُنْتُمْ فَوَلُّوا وُجُوهَكُمْ شَطْرَهُ",
                    style: AppTextStyles.madReg16(context),
                  ),
                  InkWell(
                    onTap: () {
                      navigateTo(context, QiblahCompassScreen());
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(AppColors.mainGreen),
                      ),
                      child: Center(
                        child: Text("تحديد موقعك لتوجيهك نحو القبلة",
                          style: AppTextStyles.madB14(context),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}
