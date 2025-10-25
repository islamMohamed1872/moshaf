import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/cubit/cubit.dart';
import 'package:moshaf/cubit/states.dart';
import 'package:moshaf/modules/audio_quran/audio_player_screen.dart';
import 'package:moshaf/controllers/quran_audio/audio_quran_cubit.dart';
import 'package:moshaf/controllers/quran_audio/audio_quran_states.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_cubit.dart';
import 'package:quran/quran.dart' as quran;

import '../../components/audio_service.dart';
import '../text_quran/views/quran_page.dart';

class AudioScreen extends StatelessWidget {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioQuranCubit,AudioQuranStates>(
      builder: (context,state){
        final cubit = AudioQuranCubit.get(context);
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 20.0),
                      child: Container(
                        width: double.infinity,
                        height: 45.h,
                        decoration: BoxDecoration(
                          color: HexColor("FDEDDC"),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: defaultField(
                          controller: cubit.searchController,
                          type: TextInputType.text,
                          label: "بحث",
                          validate: (String? value) {
                            return null;
                          },
                          suffix: Icons.search,
                          onChanged: (value) {
                            if (value.trim().isEmpty) {
                              cubit.errorSearch = false;
                              cubit.validSearch = false;
                              return;
                            }
                            cubit.getSorahNumber(value.trim());
                          },
                        ),
                      ),
                    ),
                    if(!cubit.errorSearch)
                      ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            int customIndex =
                            cubit.searchedSorahNumber.isEmpty
                                ? index + 1
                                : cubit.searchedSorahNumber[index];
                            return ListTile(
                              leading: SizedBox(
                                width: 50.w,
                                height: 50.w,
                                child: Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        "assets/images/sora_number.png",
                                        color: HexColor("d6bb97"),
                                        width: 50.w,
                                      ),
                                      Text(
                                        TextQuranCubit.get(context).convertToArabic((index+1).toString()),
                                        style: TextStyle(
                                          color: HexColor("333333"),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              minVerticalPadding: 0,
                              title: Text(
                                quran.getSurahNameEnglish(customIndex),
                                style:  TextStyle(
                                    color: HexColor("333333"),
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.bold // Text color
                                ),
                              ),
                              subtitle: Row(
                                spacing: 5,
                                children: [
                                  Text(
                                    "${quran.getVerseCount(customIndex).toString()} ايات ",
                                    textDirection: TextDirection.rtl,
                                    style:  TextStyle(
                                      color: HexColor("936f35"),
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  Text(
                                    quran.getPlaceOfRevelation(
                                        customIndex) ==
                                        "Makkah"
                                        ? "مكية |"
                                        : "مدنية |",
                                    textDirection: TextDirection.rtl,
                                    style:  TextStyle(
                                      color: HexColor("936f35"),
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: RichText(
                                text: TextSpan(
                                  text: customIndex.toString(),
                                  style:  TextStyle(
                                    fontFamily: "arsura",
                                    fontSize: 30.sp,
                                    color: HexColor("936f35"),
                                  ),
                                ),
                              ),
                              onTap: () {
                                AudioServices().player.stop();
                                cubit.duration = Duration.zero;
                                cubit.position = Duration.zero;
                                cubit.sorahNumber =cubit.searchedSorahNumber.isEmpty?
                                index+1:cubit.searchedSorahNumber[index];
                                navigateTo(context, QuranAudioPlayerScreen()
                                );
                              },
                            );
                          },
                          separatorBuilder: (context, index) => seperator(),
                          itemCount: cubit.searchedSorahNumber.isEmpty
                              ? cubit.homeCount
                              : cubit.searchedSorahNumber.length),
                    if(cubit.homeCount != 114 &&
                        !cubit.validSearch &&
                        !cubit.errorSearch)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 10.0),
                        child: MaterialButton(
                          color: HexColor("#936f35"),
                          onPressed: () {
                            cubit.loadMore();
                          },
                          child:  Text(
                            "المزيد",
                            style: TextStyle(
                              color: HexColor("#fdf3e8"),
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                            ),
                          ),
                        ),
                      ),
                    if(cubit.errorSearch)
                      Text(
                        "يرجي التأكد من اسم السوره",
                        style: TextStyle(
                          color: HexColor("#544f45"),
                          fontFamily: "amiri",
                          fontSize: 20.sp,
                        ),
                      ),
                    SizedBox(height: 70.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      listener: (context,state){},
    );
  }
}
