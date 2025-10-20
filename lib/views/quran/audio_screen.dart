import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/modules/audio_quran/cubit/audio_quran_cubit.dart';
import 'package:moshaf/modules/audio_quran/cubit/audio_quran_states.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_cubit.dart';
import 'package:moshaf/views/azkar/widgets/azkar_header.dart';
import 'package:moshaf/views/quran/widgets/custom_sorah_container.dart';
import 'package:quran/quran.dart';
import 'package:quran/quran.dart' as quran;

import '../../components/audio_service.dart';
import '../../components/components.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../modules/text_quran/views/quran_page.dart';

class AudioScreen extends StatelessWidget {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioQuranCubit, AudioQuranStates>(
      builder: (context, state) {
        final cubit = AudioQuranCubit.get(context);
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 20.0,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () async {
                            cubit.stop();
                            await AudioServices().player.clearAudioSources();
                            navigateTo(
                              context,
                              QuranViewPage(
                                shouldHighlightText: false,
                                highlightVerse: "",
                                jsonData:
                                    TextQuranCubit.get(context).suraJsonData,
                                pageNumber: getPageNumber(cubit.sorahNumber, 1),
                              ),
                            );
                          },
                          child: Icon(FontAwesomeIcons.fileLines),
                        ),
                        InkWell(
                          onTap: () async{
                            cubit.stop();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 30.w,
                            height: 30.w,
                            padding: EdgeInsetsDirectional.only(
                              start:
                                  context.locale.languageCode == "ar" ? 0 : 7.w,
                              top: 5,
                              bottom: 5,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(AppColors.containerBorders),
                              ),
                            ),
                            child: FittedBox(
                              child: Icon(
                                context.locale.languageCode == "ar"
                                    ? Icons.arrow_forward_ios
                                    : Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  Container(
                    width: double.infinity,
                    height: 240.h,
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 30.w,vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(AppColors.containerBorders)),
                    ),
                    child: Column(
                      children: [
                        const Spacer(),
                        RichText(
                            text: TextSpan(text: cubit.sorahNumber.toString(),
                              style: AppTextStyles.arsura40(context),
                            )),
                        const SizedBox(height: 8,),
                        Text("${quran.getPlaceOfRevelation(
                            cubit.sorahNumber) ==
                            "Makkah"
                            ? "مكية"
                            : "مدنية"} | ${quran.getVerseCount(cubit.sorahNumber)} ايات",
                        style: AppTextStyles.madXL10(context,color: Color(0xff848484)) ,
                        ),
                        SizedBox(
                          height: 30.h,
                        ),
                        _buildProgressBar(cubit,context),
                        _buildControls(cubit,state)
                      ],
                    ),
                  ),
                  const  SizedBox(
                    height: 15,
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric( horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Color(AppColors.containerBorders),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: Text(
                          'اختر القارئ',
                          style: AppTextStyles.madReg14(context),
                        ),
                        value: cubit.selecteShiekh,
                        icon: Icon(Icons.keyboard_arrow_down_rounded),
                        dropdownColor: Color(AppColors.containerBorders),
                        borderRadius: BorderRadius.circular(12.r),
                        items: cubit.shiekhList.map((String name) {
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(
                              name,
                              style: AppTextStyles.madL14(context),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          cubit.changeSelectedShiekh(newValue);
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 30.h,
                  ),
                  Expanded(
                      child: ListView.separated(
                          itemBuilder: (context, index) => CustomSorahContainer(
                            placeOfRevelation: quran.getPlaceOfRevelation(
                                index+1) ==
                                "Makkah"
                                ? "مكية"
                                : "مدنية",
                            verseCount: quran.getVerseCount(index+1),
                            sorahIndex: index,
                            onReadPressed: () async{
                              cubit.stop();
                              await AudioServices().player.clearAudioSources();
                              TextQuranCubit.get(context).soraNumber = index+1;
                              navigateTo(context, QuranViewPage(
                                shouldHighlightText: false,
                                highlightVerse: "",
                                jsonData: TextQuranCubit.get(context).suraJsonData,
                                pageNumber: getPageNumber(
                                  index+1,
                                  1,
                                ),
                              ),
                              );
                            },
                            onListenPressed: () {
                              cubit.sorahNumber = index+1;
                              cubit.stop();
                              cubit.play();
                              TextQuranCubit.get(context).soraNumber = index+1;
                            },
                          ),
                          separatorBuilder: (context, index) => SizedBox(
                            height: 7.h,
                          ),
                          itemCount: 114)
                  ),

                ],
              ),
            ),
          ),
        );
      },
      listener: (context, state) {
        print(state);
      },
    );
  }

  Widget _buildProgressBar(AudioQuranCubit cubit,context) {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(trackHeight: 1,thumbSize: MaterialStateProperty.all(Size(5, 5)),),
        child: Slider(
          activeColor: Colors.white,
          inactiveColor: HexColor("#3E3E3E"),
          padding: EdgeInsets.all(0),
          thumbColor: Color(AppColors.containerBorders),
          value: cubit.position.inSeconds
              .clamp(0, cubit.duration.inSeconds)
              .toDouble(),
          max: cubit.duration.inSeconds.toDouble(),
          onChangeEnd: (value) {
            cubit.play();
          },
          onChanged: (value) {
             // cubit.player.pause();
            cubit.seekTo(Duration(seconds: value.toInt()));
          }
              ,
        ),
      ),
    );
  }


  Widget _buildControls(AudioQuranCubit cubit,AudioQuranStates state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(FontAwesomeIcons.forwardStep, size: 20,color: Colors.white,),
          onPressed: cubit.canGoPrev ? cubit.prevSurah : null,
        ),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: () {
            if(state is !GetDataLoadingState) cubit.play();
          },
          child: CircleAvatar(
            radius: 15,
            backgroundColor: Colors.white,
            child:state is GetDataLoadingState&&cubit.duration==Duration(seconds: 0)?
            Padding(
              padding: EdgeInsets.all(2),
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            ):
            Icon(
              cubit.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 30),
        IconButton(
          icon: const Icon(FontAwesomeIcons.backwardStep, size: 20,color: Colors.white,),
          onPressed: cubit.canGoNext ? cubit.nextSurah : null,
        ),
      ],
    );
  }

}
