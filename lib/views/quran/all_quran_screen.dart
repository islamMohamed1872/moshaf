import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_cubit.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_states.dart';
import 'package:moshaf/views/quran/widgets/custom_sorah_container.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran/quran.dart';

import '../../components/audio_service.dart';
import '../../modules/text_quran/views/quran_page.dart';

class AllQuranScreen extends StatelessWidget {
  const AllQuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextQuranCubit,TextQuranStates>(
        builder: (context, state) {
          final cubit = TextQuranCubit.get(context);
          return Scaffold(
            body: SafeArea(
                child: Column(
                  spacing: 10,
              children: [
                Stack(
                  alignment: AlignmentGeometry.center,
                  children: [
                    Image.asset(
                      "assets/images/sorah_bg.png",
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
                            InkWell(
                              onTap: () {
                                cubit.togglePlayPause(cubit.savedSora);
                              },
                              child: Icon(
                                cubit.isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                                size: 20.w,
                              ),
                            ),
                            RichText(
                                text: TextSpan(text: cubit.savedSora==0?"1":cubit.savedSora.toString(),
                              style: AppTextStyles.arsura24(context),
                            ))
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      left: 10,
                      child: InkWell (
                        onTap: ()async{
                          cubit.stop();
                          await AudioServices().player.clearAudioSources();
                          cubit.soraNumber = cubit.savedSora;
                          navigateTo(context, QuranViewPage(
                            shouldHighlightText: true,
                            highlightVerse: cubit.savedVerse.toString(),
                            jsonData: cubit.suraJsonData,
                            pageNumber: getPageNumber(
                              cubit.savedSora,
                              cubit.savedVerse,
                            ),
                          )
                          );
                        },
                        child: Text(cubit.savedVerseContent,
                        textAlign: TextAlign.center,
                        maxLines:2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.arsura24(context),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsetsDirectional.symmetric(horizontal: 9.w,vertical: 3.h),
                            decoration: cubit.placeOfRevelation=="مكية"? BoxDecoration(
                              borderRadius: BorderRadius.circular(45),
                              border: Border.all(
                                color: Color(AppColors.containerBorders)
                              ),
                            ):null,
                            child: Text("مكية",
                            style: AppTextStyles.madMd12(context),
                            ),
                          ),
                          Container(
                            padding: EdgeInsetsDirectional.symmetric(horizontal: 9.w,vertical: 3.h),
                            decoration:cubit.placeOfRevelation=="مدنية"?  BoxDecoration(
                              borderRadius: BorderRadius.circular(45),
                              border: Border.all(
                                color: Color(AppColors.containerBorders)
                              ),
                            ):null,
                            child: Text("مدنية",
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
                  color: Color(AppColors.containerBorders),
                ),
                Expanded(
                    child: Padding(
                      padding: EdgeInsetsGeometry.symmetric(horizontal: 15),
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
                                cubit.soraNumber = index+1;
                                navigateTo(context, QuranViewPage(
                                  shouldHighlightText: false,
                                  highlightVerse: "",
                                  jsonData: cubit.suraJsonData,
                                  pageNumber: getPageNumber(
                                    index+1,
                                    1,
                                  ),
                                ),
                                );
                              },
                            onListenPressed: () {

                            },
                          ),
                          separatorBuilder: (context, index) => SizedBox(
                            height: 7.h,
                          ),
                          itemCount: 114),
                    )
                ),
              ],
            )
            ),
          );
        },
    );
  }
}
