import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:quran/quran.dart' as quran;

import '../../constants/app_colors.dart';

class TafseerScreen extends StatelessWidget {
  final int ayah;
  final int sorah;
  final String tafseer;
  const TafseerScreen({super.key,required this.ayah,required this.tafseer,required this.sorah});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: SingleChildScrollView(
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
                     Text("تفسير",
                     style: AppTextStyles.madReg16(context),
                     ),
                      InkWell(
                        onTap: () async{
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 30.w
                          ,
                          height: 30.w,
                          padding: EdgeInsetsDirectional.only(
                            start:
                            context.locale.languageCode == "ar" ? 0 : 7.w,
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
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20.h,
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 17,vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(AppColors.containerBorders)),
                  ),
                  child: Text(quran.getVerse(sorah,ayah),
                  style: AppTextStyles.arsura17(context,color:Color(AppColors.mainGreen)),
                  ),
                ),
                const  SizedBox(
                  height: 8,
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 14,vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(AppColors.containerBorders)),
                  ),
                  child: Text(tafseer,
                    style: AppTextStyles.madReg14(context),
                  ),
                ),
            
              ],
            ),
          ),
        ),
      ),
    );
  }
}
