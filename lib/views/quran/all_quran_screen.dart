import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moshaf/components/cache_helper.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/quran_audio/audio_quran_cubit.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_cubit.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_states.dart';
import 'package:moshaf/views/quran/audio_screen.dart';
import 'package:moshaf/views/quran/widgets/custom_sorah_container.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran/quran.dart';

import '../../components/audio_service.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../../modules/text_quran/views/quran_page.dart';

class AllQuranScreen extends StatelessWidget {
  const AllQuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
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
                            isDark?const Color(0xFF151515):Colors.white,
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
                                color: Colors.white,
                              ),
                            ),
                            RichText(
                                text: TextSpan(text: cubit.savedSora==0?"1":cubit.savedSora.toString(),
                              style: AppTextStyles.arsura24(context,color: Colors.white),
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
                        style: AppTextStyles.arsura24(context,color: Colors.white),
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
                                color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders)
                              ),
                            ):null,
                            child: Text("مكية",
                            style: AppTextStyles.madMd12(context,color: isDark?Colors.white:Colors.black),
                            ),
                          ),
                          Container(
                            padding: EdgeInsetsDirectional.symmetric(horizontal: 9.w,vertical: 3.h),
                            decoration:cubit.placeOfRevelation=="مدنية"?  BoxDecoration(
                              borderRadius: BorderRadius.circular(45),
                              border: Border.all(
                                color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders)
                              ),
                            ):null,
                            child: Text("مدنية",
                              style: AppTextStyles.madMd12(context,color: isDark?Colors.white:Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
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
                              color: Colors.white,
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
                    ),

                  ],
                ),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders),
                ),
                Expanded(
                    child: Padding(
                      padding: EdgeInsetsGeometry.symmetric(horizontal: 15),
                      child: ListView.separated(
                          itemBuilder: (context, index) => CustomSorahContainer(
                            isDark: isDark,
                              placeOfRevelation: quran.getPlaceOfRevelation(
                                  index+1) ==
                                  "Makkah"
                                  ? "مكية"
                                  : "مدنية",
                              verseCount: quran.getVerseCount(index+1),
                              sorahIndex: index,
                              onReadPressed: () async{
                                CacheHelper.saveData(key: "lastRead", value: DateTime.now().toString());
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
                                AudioQuranCubit.get(context).sorahNumber = index+1;
                                cubit.soraNumber = index+1;
                                navigateTo(context, AudioScreen());
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
