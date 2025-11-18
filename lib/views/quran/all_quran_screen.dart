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
import 'package:moshaf/controllers/text_quran/text_quran_cubit.dart';
import 'package:moshaf/controllers/text_quran/text_quran_states.dart';
import 'package:moshaf/views/quran/audio_screen.dart';
import 'package:moshaf/views/quran/widgets/custom_sorah_container.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran/quran.dart';

import '../../components/audio_service.dart';
import '../../controllers/theme/theme_cubit.dart';
import 'widgets/quran_page.dart';

class AllQuranScreen extends StatelessWidget {
  const AllQuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    return BlocBuilder<TextQuranCubit, TextQuranStates>(
      builder: (context, state) {
        final cubit = TextQuranCubit.get(context);
        final filteredSurahs = cubit.getFilteredSurahs();

        return Scaffold(
          body: SafeArea(
            child: Column(
              spacing: 10,
              children: [
                // 🔹 HEADER AREA
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
                            Colors.black.withOpacity(0),
                            isDark ? const Color(0xFF151515) : Colors.white,
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
                                cubit.isPlaying
                                    ? FontAwesomeIcons.pause
                                    : FontAwesomeIcons.play,
                                size: 20.w,
                                color: Colors.white,
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                text: cubit.savedSora == 0
                                    ? "1"
                                    : cubit.savedSora.toString(),
                                style: AppTextStyles.arsura24(context,
                                    color: Colors.white),
                              ),
                            ),
                            // 🔹 NEW FILTER BUTTON
                            InkWell(
                              onTap: () =>
                                  _showFilterDialog(context,isDark),
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Icon(
                                  FontAwesomeIcons.filter,
                                  size: 16.w,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ... (rest of your Positioned items)
                    // No change here
                    Positioned(
                      right: 10,
                      left: 10,
                      child: InkWell(
                        onTap: () async {
                          cubit.stop();
                          await AudioServices().player.clearAudioSources();
                          cubit.soraNumber = cubit.savedSora;
                          navigateTo(
                            context,
                            QuranViewPage(
                              shouldHighlightText: true,
                              highlightVerse: cubit.savedVerse.toString(),
                              jsonData: cubit.suraJsonData,
                              pageNumber: getPageNumber(
                                cubit.savedSora,
                                cubit.savedVerse,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          cubit.savedVerseContent,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.arsura24(context,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 9.w, vertical: 3.h),
                            decoration: cubit.placeOfRevelation == "مكية"
                                ? BoxDecoration(
                              borderRadius: BorderRadius.circular(45),
                              border: Border.all(
                                color: Color(isDark
                                    ? AppColors.containerDarkBorders
                                    : AppColors.containerLightBorders),
                              ),
                            )
                                : null,
                            child: Text(
                              "مكية",
                              style: AppTextStyles.madMd12(context,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 9.w, vertical: 3.h),
                            decoration: cubit.placeOfRevelation == "مدنية"
                                ? BoxDecoration(
                              borderRadius: BorderRadius.circular(45),
                              border: Border.all(
                                color: Color(isDark
                                    ? AppColors.containerDarkBorders
                                    : AppColors.containerLightBorders),
                              ),
                            )
                                : null,
                            child: Text(
                              "مدنية",
                              style: AppTextStyles.madMd12(context,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black),
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
                            start: context.locale.languageCode == "ar"
                                ? 0
                                : 7.w,
                            top: 5,
                            bottom: 5,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white),
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

                // 🔹 DIVIDER
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Color(isDark
                      ? AppColors.containerDarkBorders
                      : AppColors.containerLightBorders),
                ),

                // 🔹 FILTERED LIST
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    child: ListView.separated(
                      itemCount: filteredSurahs.length,
                      itemBuilder: (context, index) {
                        final surahNum = filteredSurahs[index];
                        return CustomSorahContainer(
                          isDark: isDark,
                          placeOfRevelation:
                          quran.getPlaceOfRevelation(surahNum) ==
                              "Makkah"
                              ? "مكية"
                              : "مدنية",
                          verseCount: quran.getVerseCount(surahNum),
                          sorahIndex: surahNum - 1,
                          onReadPressed: () async {
                            CacheHelper.saveData(
                                key: "lastRead",
                                value: DateTime.now().toString());
                            cubit.stop();
                            await AudioServices().player.clearAudioSources();
                            cubit.soraNumber = surahNum;
                            navigateTo(
                              context,
                              QuranViewPage(
                                shouldHighlightText: false,
                                highlightVerse: "",
                                jsonData: cubit.suraJsonData,
                                pageNumber: getPageNumber(surahNum, 1),
                              ),
                            );
                          },
                          onListenPressed: () {
                            AudioQuranCubit.get(context).sorahNumber =
                                surahNum;
                            cubit.soraNumber = surahNum;
                            navigateTo(context, AudioScreen());
                          },
                        );
                      },
                      separatorBuilder: (_, __) => SizedBox(height: 7.h),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔹 MODAL FILTER DIALOG
  void _showFilterDialog(BuildContext context, bool isDark) {
    final cubit = TextQuranCubit.get(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return BlocBuilder<TextQuranCubit, TextQuranStates>(
          builder: (context, state) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151515) : Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(25)),
                border: Border.all(
                  color: Color(
                    isDark
                        ? AppColors.containerDarkBorders
                        : AppColors.containerLightBorders,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Title
                  Text(
                    "تصفية حسب",
                    style: AppTextStyles.madB20(context,
                        color: isDark ? Colors.white : Colors.black),
                  ),
                  SizedBox(height: 20.h),

                  // Filter Type Tabs
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFilterTab(context, "الكل", "all", isDark),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildFilterTab(context, "رقم السورة", "surah", isDark),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildFilterTab(context, "الجزء", "juz", isDark),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Dynamic Content (auto rebuilds)
                  Expanded(
                    child: cubit.filterType == "surah"
                        ? _buildNumberPicker(context,cubit, isDark)
                        : cubit.filterType == "juz"
                        ? _buildJuzPicker(context,cubit, isDark)
                        : Center(
                      child: Text(
                        "عرض جميع السور",
                        style: AppTextStyles.madReg16(context,
                            color: isDark
                                ? Colors.white70
                                : Colors.black54),
                      ),
                    ),
                  ),

                  // Apply Button
                  Padding(
                    padding: EdgeInsets.all(15.w),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppColors.mainGreen),
                        minimumSize: Size(double.infinity, 50.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "تطبيق التصفية",
                        style: AppTextStyles.madB16(context, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }



  Widget _buildFilterTab(BuildContext context, String title, String type, bool isDark) {
    final cubit = TextQuranCubit.get(context);
    final isSelected = cubit.filterType == type;
    return InkWell(
      onTap: () => cubit.setFilterType(type),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Color(AppColors.mainGreen) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Color(AppColors.mainGreen)
                : Color(
              isDark
                  ? AppColors.containerDarkBorders
                  : AppColors.containerLightBorders,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.madB14(context,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black)),
        ),
      ),
    );
  }


  Widget _buildNumberPicker(
      BuildContext context, TextQuranCubit cubit, bool isDark) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
      ),
      itemCount: 114,
      itemBuilder: (context, index) {
        final num = index + 1;
        final selected = cubit.selectedSurah == num;
        return InkWell(
          onTap: () => cubit.setSelectedSurah(num),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? Color(AppColors.mainGreen)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected
                      ? Color(AppColors.mainGreen)
                      : Color(isDark
                      ? AppColors.containerDarkBorders
                      : AppColors.containerLightBorders)),
            ),
            child: Center(
              child: Text(
                num.toString(),
                style: AppTextStyles.madB14(context,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJuzPicker(
      BuildContext context, TextQuranCubit cubit, bool isDark) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juz = index + 1;
        final selected = cubit.selectedJuz == juz;
        return InkWell(
          onTap: () => cubit.setSelectedJuz(juz),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? Color(AppColors.mainGreen)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? Color(AppColors.mainGreen)
                    : Color(isDark
                    ? AppColors.containerDarkBorders
                    : AppColors.containerLightBorders),
              ),
            ),
            child: Center(
              child: Text(
                juz.toString(),
                style: AppTextStyles.madB16(context,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black)),
              ),
            ),
          ),
        );
      },
    );
  }
}
