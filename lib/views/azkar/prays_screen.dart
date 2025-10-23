import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/azkar.dart';
import 'package:moshaf/views/azkar/one_pray_screen.dart';
import 'package:moshaf/views/azkar/widgets/custom_azkar_container.dart';
import 'package:moshaf/views/widgets/header.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../modules/azkar/cubit/azkar_cubit.dart';
import '../../modules/azkar/cubit/azkar_states.dart';
import '../home/home_screen.dart';

class PraysScreen extends StatelessWidget {
  const PraysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AzkarCubit,AzkarStates>(
      builder: (context, state) {
        final cubit = AzkarCubit.get(context);
        return Scaffold(
          body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      alignment: AlignmentGeometry.center,
                      children: [
                        Image.asset(
                          "assets/images/prays_bg.png",
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
                          right: 0,
                          left: 0,
                          child: Header(title: cubit.doaaCategory,onTap: () {
                            navigateAndFinish(context, HomeScreen());
                          },),
                        ),
                        Positioned(
                          right: 10,
                          left: 10,
                          child: Text(cubit.randomDoaa,
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
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: EdgeInsetsDirectional.symmetric(horizontal: 9.w,vertical: 3.h),
                                  child: Text("اذكار",
                                    style: AppTextStyles.madMd12(context),
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsetsDirectional.symmetric(horizontal: 9.w,vertical: 3.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(45),
                                  border: Border.all(
                                      color: Color(AppColors.containerBorders)
                                  ),
                                ),
                                child: Text("ادعية",
                                  style: AppTextStyles.madMd12(context),
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
                    /// جوامع الدعاء
                    CustomAzkarContainer(
                        startPadding: 13,
                        endPadding: 13,
                        onTap: () {
                          navigateTo(context, OnePrayScreen(title: "جوامع الدعاء", items: AzkarConstants.jawameDoaa));
                        },
                        text: "جوامع الدعاء",
                        image: "assets/images/pray2.png"),
                    SizedBox(
                      height: 8.h,
                    ),
                    /// ادعية نبوية & قرآنية
                    Row(
                      spacing: 8.w,
                      children: [
                        Expanded(
                          child: CustomAzkarContainer(
                              startPadding: 13,
                              onTap: () {
                                navigateTo(context, OnePrayScreen(title: "ادعية نبوية", items: AzkarConstants.adeyahNabaweyah));
                              },
                              text: "ادعية نبوية",
                              image: "assets/images/pray2.png"),
                        ),
                        Expanded(
                          child: CustomAzkarContainer(
                              endPadding: 13,
                              onTap: () {
                                navigateTo(context, OnePrayScreen(title: "ادعية القرآنية", items: AzkarConstants.adeyaQuranya));
                              },
                              text: "ادعية القرآنية",
                              image: "assets/images/pray2.png"),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 8.h,
                    ),
                    /// ادعية الانبياء
                    CustomAzkarContainer(
                        startPadding: 13,
                        endPadding: 13,
                        onTap: () {
                          navigateTo(context, OnePrayScreen(title: "ادعية الانبياء", items: AzkarConstants.adeyatAlanbiya));
                        },
                        text: "ادعية الانبياء",
                        image: "assets/images/pray2.png"),
                    SizedBox(
                      height: 8.h,
                    ),
                    /// ادعية للميت & للمسلمين
                    Row(
                      spacing: 8.w,
                      children: [
                        Expanded(
                          child: CustomAzkarContainer(
                              startPadding: 13,
                              onTap: () {
                                navigateTo(context, OnePrayScreen(title: "ادعية للميت", items: AzkarConstants.adeyatAlmayet));
                              },
                              text: "ادعية للميت",
                              image: "assets/images/pray2.png"),
                        ),
                        Expanded(
                          child: CustomAzkarContainer(
                              endPadding: 13,
                              onTap: () {
                                navigateTo(context, OnePrayScreen(title: "ادعية للمسلمين", items: AzkarConstants.adeyaForAllMuslims));
                              },
                              text: "ادعية للمسلمين",
                              image: "assets/images/pray2.png"),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 8.h,
                    ),
                    /// فضل السور
                    CustomAzkarContainer(
                        startPadding: 13,
                        endPadding: 13,
                        onTap: () {
                          navigateTo(context, OnePrayScreen(title: "فضل السور", items: AzkarConstants.fadlAlSowar));
                        },
                        text: "فضل السور",
                        image: "assets/images/pray2.png"),
                    SizedBox(
                      height: 8.h,
                    ),
                    /// فضل الدعاء & الذكر
                    Row(
                      spacing: 8.w,
                      children: [
                        Expanded(
                          child: CustomAzkarContainer(
                              startPadding: 13,
                              onTap: () {
                                navigateTo(context, OnePrayScreen(title: "فضل الدعاء", items: AzkarConstants.fadlAlDoaa));
                              },
                              text: "فضل الدعاء",
                              image: "assets/images/pray2.png"),
                        ),
                        Expanded(
                          child: CustomAzkarContainer(
                              endPadding: 13,
                              onTap: () {
                                navigateTo(context, OnePrayScreen(title: "فضل الذكر", items: AzkarConstants.fadlAlThekr));
                              },
                              text: "فضل الذكر",
                              image: "assets/images/pray2.png"),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 8.h,
                    ),
                    /// الرقية بالسنة & بالقرآن
                    Row(
                      spacing: 8.w,
                      children: [
                        Expanded(
                          child: CustomAzkarContainer(
                              startPadding: 13,
                              onTap: () {
                                navigateTo(context, OnePrayScreen(title: "الرقية بالسنة", items: AzkarConstants.roqyaBelsonah));
                              },
                              text: "الرقية بالسنة",
                              image: "assets/images/pray2.png"),
                        ),
                        Expanded(
                          child: CustomAzkarContainer(
                              endPadding: 13,
                              onTap: () {
                                navigateTo(context, OnePrayScreen(title: "الرقية بالقرآن", items: AzkarConstants.roqyaBelquran));
                              },
                              text: "الرقية بالقرآن",
                              image: "assets/images/pray2.png"),
                        ),
                      ],
                    ),
                  ],
                ),
              )
          ),
        );
      },
    );
  }
}
