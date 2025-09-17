import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/modules/audio_quran/cubit/audio_quran_cubit.dart';
import 'package:moshaf/modules/azkar/cubit/azkar_cubit.dart';
import 'package:moshaf/modules/prayer_times/cubit/prayer_times_cubit.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_cubit.dart';

import '../cubit/cubit.dart';
import '../cubit/states.dart';

class AppLayout extends StatelessWidget {
  const AppLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit,AppStates>(
      builder: (context,state){
        AppCubit cubit = AppCubit.get(context);
        return Scaffold(
          body: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              cubit.bottomScreens[cubit.currentIndex],
              Positioned(
                bottom: 30,
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: ShapeDecoration(
                    color: HexColor("faf5ec"),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(66),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x265590FF),
                        blurRadius: 8,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: Row(
                    spacing: 25,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _buildNavItem(
                        context,
                        cubit,
                        index: 0,
                        icon: Icons.menu_book,
                        label: 'قراءه',
                      ),
                      _buildNavItem(
                        context,
                        cubit,
                        index: 1,
                        icon: Icons.headphones_outlined,
                        label: 'الاستماع',
                      ),
                      _buildNavItem(
                        context,
                        cubit,
                        index: 2,
                        icon: Icons.short_text_outlined,
                        label: 'الاذكار',
                      ),
                      _buildNavItem(
                        context,
                        cubit,
                        index: 3,
                        icon: Icons.alarm,
                        label: 'توقيت الصلاه',
                      ),
                      _buildNavItem(
                        context,
                        cubit,
                        index: 4,
                        icon: Icons.bookmark_border,
                        label: 'اخر قراءة',
                      )
                    ],
                  ),

                ),
              )

            ],
          ),
        );
      },
      listener: (context,state){},
     );
  }
}
Widget _buildNavItem(BuildContext context, AppCubit cubit,
    {required int index, required IconData icon, required String label}) {
  final isActive = cubit.currentIndex == index;

  return InkWell(
    borderRadius: BorderRadius.circular(48),
    onTap: () {
      cubit.changeBottom(index);
      if(index==0){
        TextQuranCubit.get(context).searchController.clear();
        TextQuranCubit.get(context).searchController.clear();
      }
      else if(index==1){
        AudioQuranCubit.get(context).searchController.clear();
        AudioQuranCubit.get(context).searchedSorahNumber.clear();
        AudioQuranCubit.get(context).errorSearch=false;
      }
      else if(index==2){
        AzkarCubit.get(context).loadAzkar();
      }
      if (index == 3) {
        // PrayerTimesCubit.get(context).startRemainingTimeUpdater();
      } else {
        // if (PrayerTimesCubit.get(context).remainingTimeTimer != null) {
        //   PrayerTimesCubit.get(context).remainingTimeTimer!.cancel();
        //   PrayerTimesCubit.get(context).remainingTimeTimer = null;
        // }
        TextQuranCubit.get(context).getLastRead();
      }
    },
    child: isActive
        ? Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: ShapeDecoration(
        color: HexColor("936f35").withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: HexColor("936f35"),
          ),
          borderRadius: BorderRadius.circular(48),
        ),
      ),
      child: Row(
        spacing: 8,
        children: [
          Icon(icon, color: HexColor("936f35")),
          Text(
            label,
            style: TextStyle(
              color: HexColor("936f35"),
              fontSize: 14.h,
              fontFamily: 'madMd',
            ),
          ),
        ],
      ),
    )
        : Icon(icon, color: HexColor("d6bb97")),
  );
}
