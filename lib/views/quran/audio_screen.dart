// lib/views/quran/audio_screen.dart
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/controllers/quran_audio/audio_quran_cubit.dart';
import 'package:moshaf/controllers/quran_audio/audio_quran_states.dart';
import 'package:moshaf/controllers/text_quran/text_quran_cubit.dart';
import 'package:moshaf/views/azkar/widgets/azkar_header.dart';
import 'package:moshaf/views/quran/playlist_screen.dart';
import 'package:moshaf/views/quran/widgets/custom_sorah_container.dart';
import 'package:quran/quran.dart';
import 'package:quran/quran.dart' as quran;

import '../../components/audio_service.dart';
import '../../components/components.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../../models/reciter_model.dart';
import 'widgets/quran_page.dart';

class AudioScreen extends StatelessWidget {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCubit = ThemeCubit.get(context);
    final isDark = themeCubit.isDark;
    final gold = AppColors.isGoldMode;

    // Colors depending on dark/gold modes
    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final primaryTextClr = gold ? const Color(AppColors.goldText) : (isDark ? Colors.white : Colors.black);

    final subtitleClr = gold ? const Color(AppColors.goldText) : (isDark ? Color(AppColors.lightBlack) : const Color(0xff848484));

    final iconClr = gold ? const Color(AppColors.goldPrimary) : (isDark ? Colors.white : Colors.black);

    final sliderActive = gold ? const Color(AppColors.goldPrimary) : (isDark ? Colors.white : Colors.black);
    final sliderThumb = gold ? const Color(AppColors.goldPrimary) : (isDark ? Color(AppColors.containerDarkBorders) : const Color(0xff000000));
    final sliderInactive = gold ? const Color(AppColors.goldBorder) : (isDark ? HexColor("#3E3E3E") : HexColor("#BFBFBF"));

    final dropdownBorderClr = gold ? const Color(AppColors.goldBorder) : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);
    final dropdownTextClr = gold ? const Color(AppColors.goldText) : (isDark ? Colors.white : Colors.black);
    final primary = AppColors.lbPrimary();

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
                                navigatedFromRecitation: false,
                                shouldHighlightText: false,
                                highlightVerse: "",
                                jsonData: TextQuranCubit.get(context).suraJsonData,
                                pageNumber: getPageNumber(cubit.sorahNumber, 1),
                              ),
                            );
                          },
                          child: Icon(
                            FontAwesomeIcons.fileLines,
                            color: iconClr,
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            cubit.stop();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 30.w,
                            height: 30.w,
                            padding: EdgeInsetsDirectional.only(
                              start: context.locale.languageCode == "ar" ? 0 : 7.w,
                              top: 5,
                              bottom: 5,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: borderClr,
                              ),
                            ),
                            child: FittedBox(
                              child: Icon(
                                context.locale.languageCode == "ar" ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                                color: iconClr,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    width: double.infinity,
                    height: 240.h,
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 30.w, vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderClr),
                    ),
                    child: Column(
                      children: [
                        const Spacer(),
                        RichText(
                          text: TextSpan(
                            text: cubit.sorahNumber.toString(),
                            style: AppTextStyles.arsura40(context, color: primaryTextClr),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${quran.getPlaceOfRevelation(cubit.sorahNumber) == "Makkah" ? "مكية" : "مدنية"} | ${quran.getVerseCount(cubit.sorahNumber)} ايات",
                          style: AppTextStyles.madXL10(context, color: subtitleClr),
                        ),
                        SizedBox(height: 30.h),
                        _buildProgressBar(cubit, context, isDark, gold, sliderActive, sliderInactive, sliderThumb),
                        _buildControls(cubit, state, isDark, gold),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: dropdownBorderClr),
                    ),
                    child: InkWell(
                      onTap: () {
                        cubit.openReciterSelector(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric( vertical: 14),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cubit.selectedReciter?.name ?? 'اختر القارئ',
                              style: AppTextStyles.madReg14(
                                context,
                                color: dropdownTextClr,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: dropdownTextClr,
                            ),
                          ],
                        ),
                      ),
                    ),


                  ),
                  SizedBox(height: 30.h),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsetsDirectional.only(bottom: 70),
                      itemBuilder: (context, index) {
                        final surahNumber = index + 1;
                        return CustomSorahContainer(
                          isDark: isDark,
                          borderColor: gold ? const Color(AppColors.goldBorder) : null,
                          placeOfRevelation: quran.getPlaceOfRevelation(surahNumber) == "Makkah" ? "مكية" : "مدنية",
                          verseCount: quran.getVerseCount(surahNumber),
                          sorahIndex: index,
                          onRowPressed: () {
                            cubit.sorahNumber = surahNumber;
                            cubit.stop();
                            cubit.play();
                            TextQuranCubit.get(context).soraNumber = surahNumber;
                          },
                          onReadPressed: () async {
                            cubit.stop();
                            await AudioServices().player.clearAudioSources();
                            TextQuranCubit.get(context).soraNumber = surahNumber;
                            navigateTo(
                              context,
                              QuranViewPage(
                                navigatedFromRecitation: false,
                                shouldHighlightText: false,
                                highlightVerse: "",
                                jsonData: TextQuranCubit.get(context).suraJsonData,
                                pageNumber: getPageNumber(surahNumber, 1),
                              ),
                            );
                          },
                          onListenPressed: () {
                            cubit.sorahNumber = surahNumber;
                            cubit.stop();
                            cubit.play();
                            TextQuranCubit.get(context).soraNumber = surahNumber;
                          },
                        );
                      },
                      separatorBuilder: (context, index) => SizedBox(height: 7.h),
                      itemCount: 114,
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlaylistScreen(),
                ),
              );
            },

            backgroundColor: primary,

            // ✅ important for contrast
            foregroundColor: Colors.white,

            icon: const Icon(Icons.playlist_play),
            label: Text(
              'قائمتي',
              style: AppTextStyles.madReg12(context, color: Colors.white),
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
      listener: (context, state) {
        // Optional: you can handle side-effects here.
      },
    );
  }

  Widget _buildProgressBar(
      AudioQuranCubit cubit,
      BuildContext context,
      bool isDark,
      bool gold,
      Color sliderActive,
      Color sliderInactive,
      Color sliderThumb,
      ) {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 1,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: SliderComponentShape.noOverlay,
        ),
        child: Slider(
          activeColor: sliderActive,
          inactiveColor: sliderInactive,
          value: cubit.position.inSeconds.clamp(0, cubit.duration.inSeconds).toDouble(),
          max: cubit.duration.inSeconds.toDouble().clamp(1, double.infinity),
          onChangeEnd: (value) {
            cubit.play();
          },
          onChanged: (value) {
            cubit.seekTo(Duration(seconds: value.toInt()));
          },
        ),
      ),
    );
  }

  Widget _buildControls(AudioQuranCubit cubit, AudioQuranStates state, bool isDark, bool gold) {
    final borderAndBg = gold ? const Color(AppColors.goldPrimary) : (isDark ? Colors.white : Colors.black);
    final iconColor = isDark ? Colors.black : Colors.white; // you wanted icon black on gold/button white per previous screens

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(FontAwesomeIcons.forwardStep, size: 20, color: gold ? const Color(AppColors.goldPrimary) : (isDark ? Colors.white : Colors.black)),
          onPressed: cubit.canGoPrev ? cubit.prevSurah : null,
        ),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: () {
            if (state is! GetDataLoadingState) cubit.play();
          },
          child: CircleAvatar(
            radius: 20,
            backgroundColor: borderAndBg,
            child: state is GetDataLoadingState && cubit.duration == Duration(seconds: 0)
                ? Padding(
              padding: const EdgeInsets.all(2),
              child: CircularProgressIndicator(
                color: gold ? Colors.black : (isDark ? Colors.black : Colors.white),
              ),
            )
                : Icon(
              cubit.isPlaying ? Icons.pause : Icons.play_arrow,
              color: iconColor,
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 30),
        IconButton(
          icon: Icon(FontAwesomeIcons.backwardStep, size: 20, color: gold ? const Color(AppColors.goldPrimary) : (isDark ? Colors.white : Colors.black)),
          onPressed: cubit.canGoNext ? cubit.nextSurah : null,
        ),
      ],
    );
  }
}
