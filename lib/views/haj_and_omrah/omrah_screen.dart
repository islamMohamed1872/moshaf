import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/views/haj_and_omrah/haj_screen.dart';
import 'package:moshaf/views/home/home_screen.dart';

import '../../components/components.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../widgets/header.dart';

class OmrahScreen extends StatelessWidget {
  const OmrahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List steps=[
      {
        "title" :"الإحرام:",
        "step" :" نية الدخول في النسك ولبس ملابس الإحرام والتلبية"
      },
      {
        "title" :"الطواف:",
        "step" :" الطواف سبعة أشواط حول الكعبة"
      },
      {
        "title" :"السعي:",
        "step" :" السعي بين الصفا والمروة سبعة أشواط"
      },
      {
        "title" :"الحلق أو التقصير",
        "step" :" الحلق أفضل للرجال، والتقصير للنساء"
      },
    ];
    return Scaffold(
      body: SafeArea(
          child: Column(
            children: [
              Stack(
                alignment: AlignmentGeometry.center,
                children: [
                  Image.asset(
                    "assets/images/haj_and_omrah.png",
                    height: 220.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    width: double.infinity,
                    height: 220.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0),
                          const Color(0xFF151515),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 20,
                    child: InkWell(
                      onTap: () async{
                        navigateAndFinish(context, HomeScreen());
                      },
                      child: Container(
                        width: 30.w
                        ,
                        height: 30.w,
                        padding: EdgeInsetsDirectional.only(
                          top: 5,
                          bottom: 5,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(AppColors.containerBorders),
                          ),
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
                  Positioned(
                    right: 10,
                    left: 10,
                    child: Text("وَأَتِموا الْحَجَّ وَالْعُمْرَةَ لِلَّهِ",
                      textAlign: TextAlign.center,
                      maxLines:2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.kufi24(context),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsetsDirectional.symmetric(horizontal: 9.w,vertical: 3.h),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(45),
                            border: Border.all(
                                color: Color(AppColors.containerBorders)
                            ),
                          ),
                          child: Text("العمرة",
                            style: AppTextStyles.madMd12(context),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            navigateAndFinish(context, HajScreen());
                          },
                          child: Container(
                            padding: EdgeInsetsDirectional.symmetric(horizontal: 9.w,vertical: 3.h),
                            child: Text("الحج",
                              style: AppTextStyles.madMd12(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
              Container(
                width: double.infinity,
                height: 1,
                margin: EdgeInsetsDirectional.symmetric(vertical: 10),
                color: Color(AppColors.containerBorders),
              ),
             Expanded(
                 child: ListView.separated(
                   padding: EdgeInsetsDirectional.symmetric(horizontal: 14),
                 itemBuilder: (context, index) => Container(
                   padding: EdgeInsetsDirectional.symmetric(vertical: 12,horizontal: 15),
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(10),
                     border: Border.all(color: Color(AppColors.containerBorders)),
                   ),
                   child: RichText(text: TextSpan(
                     children: [
                       TextSpan(text: steps[index]['title'],
                       style: AppTextStyles.madB14(context,color: Color(AppColors.mainGreen))
                       ),
                       TextSpan(text: steps[index]['step'],
                       style: AppTextStyles.madReg14(context)
                       ),
                     ]
                   )),
                 ), separatorBuilder: (context, index) => SizedBox(height: 8.h,),
                 itemCount: steps.length))
            ],
          )
      ),
    );
  }
}
