import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/components/const.dart';
import 'package:moshaf/modules/audio_quran/audio_screen.dart';
import 'package:moshaf/modules/audio_quran/cubit/audio_quran_cubit.dart';
import 'package:moshaf/modules/audio_quran/cubit/audio_quran_states.dart';

class ShiekhScreen extends StatelessWidget {
  const ShiekhScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AudioQuranCubit, AudioQuranStates>(
          builder: (context, state) {
            final cubit = AudioQuranCubit.get(context);
            return Padding(
              padding: const EdgeInsetsDirectional.only(start: 20.0,
              end: 20,
                top: 20,
                bottom: 100
              ),
              child: GridView.builder(
                itemCount: cubit.shiekhList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // two columns
                  crossAxisSpacing: 15.w,
                  mainAxisSpacing: 15.h,
                  childAspectRatio: 1.1.h, // adjust to make image+text look balanced
                ),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    cubit.selecteShiekh = cubit.shiekhList[index];
                    navigateTo(context, AudioScreen());
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: HexColor("#fdf3e8"),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 100.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: HexColor("#fffbf7"),
                            image: DecorationImage(
                              image: AssetImage(
                                "assets/images/${cubit.shiekhList[index]}.png",
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          cubit.shiekhList[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: "hafs",
                            color: mainTextColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
