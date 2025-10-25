import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/views/widgets/header.dart';
import 'package:quran/quran.dart' as quran;

import '../../constants/app_colors.dart';
import '../../controllers/theme/theme_cubit.dart';

class TafseerScreen extends StatelessWidget {
  final int ayah;
  final int sorah;
  final String tafseer;
  const TafseerScreen({super.key,required this.ayah,required this.tafseer,required this.sorah});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Header(title: "تفسير",isDark:isDark,iconColor: isDark?Colors.white:Colors.black,),
                SizedBox(
                  height: 20.h,
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 17,vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders)),
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
                    border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders)),
                  ),
                  child: Text(tafseer,
                    style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),
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
