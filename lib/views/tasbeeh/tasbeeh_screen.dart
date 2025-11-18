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
import 'package:moshaf/views/widgets/custom_green_button.dart';
import 'package:moshaf/views/widgets/header.dart';

import '../../controllers/theme/theme_cubit.dart';

class TasbeehScreen extends StatelessWidget {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    return BlocProvider(create: (context) => TasbeehCubit()..getData(),
    child: BlocBuilder<TasbeehCubit,TasbeehStates>(
        builder: (context, state) {
          final cubit = TasbeehCubit.get(context);
          return Scaffold(
            body: SafeArea(child: GestureDetector(
              onTap: (){
                cubit.increment();
              },
              child: Column(
                children: [
                  Header(title: "السبحة",isDark: isDark,iconColor: isDark?Colors.white:Colors.black,),
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
                            cubit.resetAll();
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
                                    child: Text(cubit.totalCount.toString().padLeft(2,"0"),style: AppTextStyles.madB85(context,color: Color(AppColors.mainGreen)),)),
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
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 15.0),
                    child: CustomGreenButton(
                      text: cubit.showInput ? "إلغاء" : "اضافة تسبيح",
                      onTap: () {
                        cubit.toggleShowInput();
                        cubit.tasbeehController.clear();
                      },
                    ),
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: cubit.showInput
                        ? Padding(
                      key: const ValueKey("inputField"),
                      padding: EdgeInsets.symmetric(
                          horizontal: 15.w,),
                      child: Container(
                        padding: EdgeInsetsDirectional.symmetric(vertical: 12.h,horizontal: 12.w),
                        height: 50.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(AppColors.mainGreen),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: cubit.tasbeehController,
                                textDirection: TextDirection.rtl,
                                style: AppTextStyles.madB14(
                                  context,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: "أدخل التسبيح الجديد...",
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13.sp,
                                  ),
                                  border: InputBorder.none,
                                  // contentPadding:
                                  // EdgeInsets.symmetric(
                                  //     horizontal: 12.w,
                                  //     vertical: 10.h),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                final text =
                                cubit.tasbeehController.text.trim();
                                if (text.isNotEmpty) {
                                  cubit.addTasbeeh(text);
                                  cubit.toggleShowInput();
                                  cubit.tasbeehController.clear();
                                }
                              },
                              child: Container(
                                // padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Color(AppColors.mainGreen),
                                  borderRadius:
                                  const BorderRadius.only(
                                    topRight: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: FittedBox(
                                    child: const Icon(Icons.check,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        : null,
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  SizedBox(
                    height: 200.h,
                    child: ListView.separated(
                      shrinkWrap: true,
                          itemBuilder: (context, index) => Dismissible(
                            key: ValueKey(cubit.tasbeehList[index]['text']),
                            direction: DismissDirection.endToStart, // swipe left
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              color: Colors.red.withOpacity(0.7),
                              child: const Icon(Icons.delete, color: Colors.white, size: 24),
                            ),
                            onDismissed: (_) {
                              cubit.deleteTasbeeh(index);
                            },
                            child: InkWell(
                              onTap: () {
                                cubit.selectTasbeeh(index);
                              },
                              child: Container(
                                width: double.infinity,
                                margin: EdgeInsetsDirectional.symmetric(horizontal: 15.w),
                                padding: EdgeInsetsDirectional.symmetric(vertical: 12.h,horizontal: 12.w),
                                decoration: BoxDecoration(
                                    border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders)),
                                    borderRadius: BorderRadius.circular(10)
                                ),
                                child: Row(
                                  children: [
                                    Text(cubit.tasbeehList[index]['text'],
                                    style: AppTextStyles.madB14(context,color: isDark?Colors.white:Colors.black),
                                    ),
                                    SizedBox(
                                      width: 20.w,
                                    ),
                                    Text(cubit.tasbeehList[index]['count'].toString(),
                                      style: AppTextStyles.madB14(context,color: isDark?Colors.white:Colors.black),
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 20.w,
                                      height: 20.w,
                                      decoration:cubit.selectedIndex==index?
                                      BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(AppColors.mainGreen),
                                      ):
                                      BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders)
                                        ) ,
                                      ),
                                      child: cubit.selectedIndex==index?FittedBox(child: Icon(Icons.check,)):null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        separatorBuilder: (context, index) => SizedBox(
                          height: 8,
                        ),
                        itemCount: cubit.tasbeehList.length),
                  ),

                  Expanded(child: TasbeehAnimation())
                ],
              ),
            )),
          );
        },
    ),
    );
  }
}

