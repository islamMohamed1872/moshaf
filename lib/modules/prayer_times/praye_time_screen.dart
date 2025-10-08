import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/modules/prayer_times/cubit/prayer_times_cubit.dart';
import 'package:moshaf/modules/prayer_times/cubit/prayer_times_states.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PrayTimeScreen extends StatelessWidget {
  const PrayTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PrayerTimesCubit, PrayerTimesStates>(
      listener: (_, __) {},
      builder: (context, state) {
        final cubit = PrayerTimesCubit.get(context);
        return Scaffold(
          body: SafeArea(
            child: Skeletonizer(
              enabled: !cubit.hasData,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Detect screen size
                  final isSmallScreen = constraints.maxWidth < 360;
                  final screenWidth = constraints.maxWidth;

                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Image.asset("assets/images/4.png",
                                    semanticLabel: 'background image'),
                                Container(
                                  width: double.infinity,
                                  color: HexColor("#795546").withValues(alpha: 0.8),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 12 : 20,
                                    vertical: isSmallScreen ? 40.h : 70.h,
                                  ),
                                  child: Column(
                                    children: [
                                      _UpcomingPrayerHeader(
                                        cubit: cubit,
                                        isSmallScreen: isSmallScreen,
                                      ),
                                      const Spacer(),
                                      _SunInfoRow(
                                        cubit: cubit,
                                        isSmallScreen: isSmallScreen,
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: Container(color: Colors.white)),
                        ],
                      ),
                      _PrayerTimesCard(
                        cubit: cubit,
                        isSmallScreen: isSmallScreen,
                        screenWidth: screenWidth,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UpcomingPrayerHeader extends StatelessWidget {
  final PrayerTimesCubit cubit;
  final bool isSmallScreen;

  const _UpcomingPrayerHeader({
    required this.cubit,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            cubit.pastEvent == null ? "" : cubit.pastEvent!['name'].toString(),
            style: TextStyle(
              color: HexColor("#fdeddc"),
              fontSize: isSmallScreen ? 35.sp : 50.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: isSmallScreen ? 5 : 10),
        Container(
          width: isSmallScreen ? 3 : 5,
          height: isSmallScreen ? 80.h : 120.h,
          decoration: BoxDecoration(
            color: HexColor("#fdeddc"),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        SizedBox(width: isSmallScreen ? 5 : 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "الصلاة القادمة",
              style: TextStyle(
                color: HexColor("#fdeddc"),
                fontSize: isSmallScreen ? 20.sp : 30.sp,
              ),
            ),
            Row(
              children: [
                Text(
                  cubit.convertToArabic(cubit.upcomingPrayerTime),
                  style: TextStyle(
                    color: HexColor("#fdeddc"),
                    fontSize: isSmallScreen ? 13.sp : 17.sp,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 4 : 8),
                Text(
                  cubit.upComingPrayer,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 16.sp : 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              cubit.remainingTime,
              style: TextStyle(
                color: HexColor("#fdeddc"),
                fontSize: isSmallScreen ? 11.sp : 14.sp,
              ),
            ),
            Text(
              "علي الأذان",
              style: TextStyle(
                color: HexColor("#fdeddc"),
                fontSize: isSmallScreen ? 11.sp : 14.sp,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SunInfoRow extends StatelessWidget {
  final PrayerTimesCubit cubit;
  final bool isSmallScreen;

  const _SunInfoRow({
    required this.cubit,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SunInfoItem(
          icon: Icons.sunny_snowing,
          label: "الغروب",
          time: cubit.convertToArabic(cubit.sunsetTime),
          isSmallScreen: isSmallScreen,
        ),
        const Spacer(),
        _SunInfoItem(
          icon: Icons.sunny,
          label: "الشروق",
          time: cubit.convertToArabic(cubit.sunriseTime),
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }
}

class _SunInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final bool isSmallScreen;

  const _SunInfoItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: isSmallScreen ? 16.w : 20.w,
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 12.sp : 15.sp,
          ),
        ),
        Text(
          time,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 12.sp : 15.sp,
          ),
        ),
      ],
    );
  }
}

class _PrayerTimesCard extends StatelessWidget {
  final PrayerTimesCubit cubit;
  final bool isSmallScreen;
  final double screenWidth;

  const _PrayerTimesCard({
    required this.cubit,
    required this.isSmallScreen,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final times = cubit.prayerTimesList;

    return Positioned(
      bottom: isSmallScreen ? 60.h : 100.h,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 20,
        ),
        child: Container(
          width: screenWidth - (isSmallScreen ? 24 : 40),
          constraints: BoxConstraints(
            maxHeight: isSmallScreen ? 280.h : 340.h,
            minHeight: 200.h,
          ),
          decoration: BoxDecoration(
            color: HexColor("faf5ec"),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 5),
              )
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 20,
            vertical: isSmallScreen ? 12 : 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "اليوم / ${cubit.dayName}",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10.sp : 13.sp,
                            fontWeight: FontWeight.bold,
                            color: HexColor("#4f4741"),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${cubit.hijriDate} / ${cubit.date}",
                          style: TextStyle(
                            color: HexColor("#4f4741"),
                            fontSize: isSmallScreen ? 10.sp : 14.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 8),
                  Icon(
                    Icons.calendar_month,
                    size: isSmallScreen ? 16.w : 20.w,
                    color: HexColor("#4f4741"),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: times.length,
                  separatorBuilder: (context, index) => Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 6 : 10,
                    ),
                    child: Container(
                      height: 0.5,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final p = times[index];
                    return Row(
                      children: [
                        Text(
                          cubit.convertToArabic(p['time']!),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14.sp : 20.sp,
                            color: HexColor("#4f4741"),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          p['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14.sp : 20.sp,
                            color: HexColor("#4f4741"),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}