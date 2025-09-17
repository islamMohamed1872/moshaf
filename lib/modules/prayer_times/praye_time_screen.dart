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
              child: Stack(
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
                                horizontal: 20,
                                vertical: 70.h,
                              ),
                              child: Column(
                                children: [
                                  _UpcomingPrayerHeader(cubit: cubit),
                                  const Spacer(),
                                  _SunInfoRow(cubit: cubit),
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
                  _PrayerTimesCard(cubit: cubit,  ),
                ],
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

  const _UpcomingPrayerHeader({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          cubit.pastEvent==null?"":cubit.pastEvent!['name'].toString(),
          style: TextStyle(
            color: HexColor("#fdeddc"),
            fontSize: 50.sp,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 5,
          height: 120.h,
          decoration: BoxDecoration(
            color: HexColor("#fdeddc"),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "الصلاة القادمة",
              style: TextStyle(
                color: HexColor("#fdeddc"),
                fontSize: 30.sp,
              ),
            ),
            Row(
              children: [
                Text(
                  cubit.convertToArabic(cubit.upcomingPrayerTime),
                  style: TextStyle(
                    color: HexColor("#fdeddc"),
                    fontSize: 17.sp,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  cubit.upComingPrayer,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              cubit.remainingTime,
              style: TextStyle(
                color: HexColor("#fdeddc"),
                fontSize: 14.sp,
              ),
            ),
            Text(
              "علي الأذان",
              style: TextStyle(
                color: HexColor("#fdeddc"),
                fontSize: 14.sp,
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
  const _SunInfoRow({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SunInfoItem(
          icon: Icons.sunny_snowing,
          label: "الغروب",
          time: cubit.convertToArabic(cubit.sunsetTime),
        ),
        const Spacer(),
        _SunInfoItem(
          icon: Icons.sunny,
          label: "الشروق",
          time: cubit.convertToArabic(cubit.sunriseTime),
        ),
      ],
    );
  }
}

class _SunInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  const _SunInfoItem({
    required this.icon,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20.w),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
          ),
        ),
        Text(
          time,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
          ),
        ),
      ],
    );
  }
}

class _PrayerTimesCard extends StatelessWidget {
  final PrayerTimesCubit cubit;

  const _PrayerTimesCard({
    required this.cubit,

  });

  @override
  Widget build(BuildContext context) {
    final times = cubit.prayerTimesList; // List<Map<String, String>> [{name, time}, ...]

    return Positioned(
      bottom: 100.h,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          width: MediaQuery.of(context).size.width-40,
          height: 340.h,
          decoration: BoxDecoration(
            color: HexColor("faf5ec"),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 5))],
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("اليوم / ${cubit.dayName}",
                          style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: HexColor("#4f4741"))),
                      Text("${cubit.hijriDate} / ${cubit.date}",
                          style: TextStyle(color: HexColor("#4f4741"),
                              fontSize: 14.sp)
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_month, size: 20.w,
                  color: HexColor("#4f4741"),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ...times.map((p) => Column(
                children: [
                  Row(
                    children: [
                      Text(
                        cubit.convertToArabic(p['time']!),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                          color: HexColor("#4f4741"),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        p['name']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                          color: HexColor("#4f4741"),
                        ),
                      ),
                    ],
                  ),
                  if (p != times.last)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Container(height: 0.5, color: Colors.grey.withValues(alpha: 0.5)),
                    ),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}
