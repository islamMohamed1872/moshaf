import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/views/mosque_location/nearest_mosques_screen.dart';
import 'package:moshaf/views/widgets/custom_green_button.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';

class MosqueLocationScreen extends StatelessWidget {
  const MosqueLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const Spacer(),
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
                          color: Color(AppColors.containerBorders),
                        ),
                      ),
                      child: Text("رجوع",style: AppTextStyles.madReg14(context),),
                    ),
                  ),

                ],
              ),
            ),
            const Spacer(),
            Image.asset("assets/images/mosque_location.png",width: 340.w,),
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
                  Text("المساجد القريبة",
                    style: AppTextStyles.madB20(context),
                  ),
                  Text(" إِنَّمَا يَعْمُرُ مَسَاجِدَ اللَّهِ مَنْ آمَنَ بِاللَّهِ وَالْيَوْمِ الْآخِرِ وَأَقَامَ الصَّلَاةَ وَآتَى الزَّكَاةَ وَلَمْ يَخْشَ إِلَّا اللَّهَ فَعَسَى أُولَئِكَ أَنْ يَكُونُوا مِنَ الْمُهْتَدِينَُ",
                    style: AppTextStyles.madReg16(context),
                    textAlign: TextAlign.center,
                  ),
                  CustomGreenButton(
                      text: "اعثر على أقرب مسجد إلى موقعك",
                      onTap: () {
                        navigateTo(context, MasjidLocatorScreen());
                      },
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
