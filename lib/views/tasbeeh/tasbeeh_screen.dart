import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/tasbeeh/tasbeeh_cubit.dart';
import 'package:moshaf/controllers/tasbeeh/tasbeeh_states.dart';
import 'dart:math';

import 'package:moshaf/views/tasbeeh/tasbeeh_animation.dart';
import 'package:moshaf/views/widgets/header.dart';

import '../../controllers/theme/theme_cubit.dart';

class TasbeehScreen extends StatelessWidget {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    return BlocProvider(create: (context) => TasbeehCubit()..getCounter(),
    child: BlocBuilder<TasbeehCubit,TasbeehStates>(
        builder: (context, state) {
          final cubit = TasbeehCubit.get(context);
          return Scaffold(
            body: SafeArea(child: Column(
              children: [
                Header(title: "السبحة",isDark: isDark,),
                SizedBox(
                  height: 25.h,
                ),
                Container(
                  margin: EdgeInsetsDirectional.symmetric(horizontal: 15.w),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders))
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.symmetric(horizontal: 15.w,vertical: 15.h),
                        child: IconButton(onPressed: () {
                          cubit.reset();
                        },
                            icon: Icon(FontAwesomeIcons.arrowRotateRight,size: 15.w,)),
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsetsDirectional.symmetric(vertical: 31.h),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                  bottom: 0,
                                  // right: 30.w,
                                  child: Text(cubit.counter.toString().padLeft(2,"0"),style: AppTextStyles.madB85(context,color: Color(AppColors.mainGreen)),)),
                              Text("مـــــــــــرات",style: AppTextStyles.madL40(context,color: isDark?Colors.white:Colors.black),),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40.h,
                ),
                ListView.separated(
                  shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) => Container(
                      width: double.infinity,
                      margin: EdgeInsetsDirectional.symmetric(horizontal: 15.w),
                      padding: EdgeInsetsDirectional.symmetric(vertical: 12.h,horizontal: 12.w),
                      decoration: BoxDecoration(
                          border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders)),
                          borderRadius: BorderRadius.circular(10)
                      ),
                      child: Text(cubit.tasbeeh[index],
                      style: AppTextStyles.madB14(context,color: isDark?Colors.white:Colors.black),
                      ),
                    ),
                    separatorBuilder: (context, index) => SizedBox(
                      height: 8,
                    ),
                    itemCount: cubit.tasbeeh.length),

                Expanded(child: TasbeehAnimation())
              ],
            )),
          );
        },
    ),
    );
  }
}

