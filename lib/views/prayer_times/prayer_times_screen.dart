import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/modules/prayer_times/cubit/prayer_times_cubit.dart';
import 'package:moshaf/modules/prayer_times/cubit/prayer_times_states.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesCubit,PrayerTimesStates>(builder: (context, state) {
      final cubit = PrayerTimesCubit.get(context);
      return Scaffold(
        body: SafeArea(child:
        Column(
          children: [
            Stack(
              alignment: AlignmentGeometry.center,
              children: [
                Image.asset(
                  "assets/images/asr_bg.png",
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
                  top: 0,
                  right: 0,
                  left: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cubit.getDayName(),
                          style: AppTextStyles.kufi24(context,color: Colors.black),
                        ),
                        Text(cubit.getHijriMonth(),
                          style: AppTextStyles.kufi24(context,color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text("صلاة ${cubit.upComingPrayer} بعد",
                      style: AppTextStyles.madReg18(context,color: Colors.white),
                    ),
                    Text(cubit.remainingTime,
                      style: AppTextStyles.madReg40(context,color: Colors.white),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined,color: Colors.white,),
                        Text("${cubit.translateToArabic(cubit.city)}, ${cubit.translateToArabic(cubit.country)}",
                          style: AppTextStyles.madL16(context),
                        )
                      ],
                    )
                  ],
                ),

              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: EdgeInsetsDirectional.only(start: 20),
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white
                  ),
                  child: Icon(Icons.arrow_back_ios,color: Colors.black,size: 10.w,),
                ),
                Text("${cubit.getDayName()} ${cubit.hijriDate} - ${cubit.date}",
                  style: AppTextStyles.madL14(context),
                ),
                Container(
                  margin: EdgeInsetsDirectional.only(end: 20),
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white
                  ),
                  child: Icon(Icons.arrow_forward_ios,color: Colors.black,size: 10.w,),
                ),

              ],
            ),
            SizedBox(
              height: 20.h,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
              child: Skeletonizer(
                enabled: cubit.prayerTimesList.isEmpty,
                child: ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index){
                      final prayerName = cubit.prayerTimesList.isEmpty? "loading": cubit.prayerTimesList[index]['name'].toString();
                      final time = cubit.prayerTimesList.isEmpty? "loading": cubit.convertToArabic(cubit.prayerTimesList[index]['time'].toString());
                      final iqama = cubit.prayerTimesList.isEmpty? "loading": cubit.convertToArabic(cubit.prayerTimesList[index]['iqama'].toString());
                      return Container(
                        width: double.infinity,
                        height: 50.h,
                        padding: EdgeInsetsDirectional.symmetric(horizontal: 20,vertical: 15.h),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Color(AppColors.containerBorders)
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(prayerName,
                              style: AppTextStyles.madL14(context,color: cubit.upComingPrayer==prayerName?Color(0xffFFD900):Colors.white),
                            ),
                            const SizedBox(
                              width: 7,
                            ),
                            Text(time,
                              style: AppTextStyles.madReg14(context,color: cubit.upComingPrayer==prayerName?Color(0xffFFD900):Colors.white),
                            ),
                            const Spacer(),
                            Text(index==1?"بداية الشروق ${cubit.convertToArabic(iqama)}":"الاقامة ${cubit.convertToArabic(iqama)}",
                              style: AppTextStyles.madL12(context,color: cubit.upComingPrayer==prayerName?Color(0xffFFD900):Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(height: 7.h,),
                    itemCount: 6),
              ),
            ),
            SizedBox(height: 7.h,),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
              child: Skeletonizer(
                enabled: cubit.prayerTimesList.isEmpty,
                child: Container(
                  width: double.infinity,
                  height: 50.h,
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 20,vertical: 15.h),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Color(AppColors.containerBorders)
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("منتصف الليل",
                        style: AppTextStyles.madL14(context),
                      ),
                      const SizedBox(
                        width: 7,
                      ),
                      Text(cubit.prayerTimesList.isEmpty?"loading":cubit.convertToArabic(cubit.prayerTimesList[6]['time'].toString()),
                        style: AppTextStyles.madReg14(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 7.h,),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
              child: Skeletonizer(
                enabled: cubit.prayerTimesList.isEmpty,
                child: Container(
                  width: double.infinity,
                  height: 50.h,
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 20,vertical: 15.h),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Color(AppColors.containerBorders)
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("الثلث الاخير",
                        style: AppTextStyles.madL14(context),
                      ),
                      const SizedBox(
                        width: 7,
                      ),
                      Text(cubit.prayerTimesList.isEmpty?"loading":cubit.convertToArabic(cubit.prayerTimesList[7]['time'].toString()),
                        style: AppTextStyles.madReg14(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
        ),
      );
    },
    );
  }
}
