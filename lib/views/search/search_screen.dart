import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/text_quran/text_quran_cubit.dart';
import 'package:moshaf/controllers/text_quran/text_quran_states.dart';
import 'package:moshaf/views/widgets/header.dart';
import 'package:quran/quran.dart' as quran;
import 'package:string_validator/string_validator.dart';

import '../../components/audio_service.dart';
import '../../components/cache_helper.dart';
import '../../components/components.dart';
import '../../controllers/quran_audio/audio_quran_cubit.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../quran/audio_screen.dart';
import '../quran/widgets/custom_sorah_container.dart';
import '../quran/widgets/quran_page.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextQuranCubit,TextQuranStates>(
        builder: (context, state) {
          final cubit = TextQuranCubit.get(context);
          final isDark = context.select((ThemeCubit cubit) => cubit.isDark,);
          return Scaffold(
            body: SafeArea(child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Header(title: "بحث", isDark: isDark),
                    SizedBox(
                      height: 20.h,
                    ),
                    Container(
                      width: double.infinity,
                      height: 45.h,
                      decoration: BoxDecoration(
                        color: isDark?Colors.white:Colors.black,
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: TextFormField(
                          cursorColor: isDark?Colors.black:Colors.white,
                          textDirection: TextDirection.rtl,
                          controller: cubit.searchController,
                          onChanged: (value) {
                            cubit.changeSearchQuery(value);
                            if (value == "") {
                              cubit.pageNumbers.clear();
                              cubit.ayatFiltered = null;
                              cubit.loadJsonAsset();
                            }
                            if (cubit.searchQuery.isNotEmpty &&
                                isInt(cubit.searchQuery) &&
                                toInt(cubit.searchQuery) < 605 &&
                                toInt(cubit.searchQuery) > 0) {
                              cubit.pageNumbers.add(toInt(cubit.searchQuery));
                            }
                
                            if (cubit.searchQuery.length >= 3 ||
                                cubit.searchQuery.toString().contains(" ")||
                                cubit.searchController.text=="ق"||
                                cubit.searchController.text=="يس"||
                                cubit.searchController.text=="طه") {
                              cubit.searchForData();
                            }
                          },
                          style: const TextStyle(
                            color: Color.fromARGB(190, 0, 0, 0),
                          ),
                
                          decoration: InputDecoration(
                            prefixIcon: IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.search),
                            ),
                            contentPadding: EdgeInsetsDirectional.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                            hintText: 'بحث بإسم السورة او الآية',
                            hintStyle: AppTextStyles.madReg12(context,color: isDark?Colors.black:Colors.white),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          int suraNumber = index + 1;
                          String suraName = "";
                          int suraNumberInQuran = 0;
                          if(cubit.filteredData!=null && cubit.filteredData!.isNotEmpty){
                            // print(cubit.filteredData);
                            suraName = cubit.filteredData![index]["englishName"];
                            suraNumberInQuran = cubit.filteredData![index]["number"];
                          }
                          return CustomSorahContainer(
                            isDark: isDark,
                            placeOfRevelation: quran.getPlaceOfRevelation(
                                suraNumber) ==
                                "Makkah"
                                ? "مكية"
                                : "مدنية",
                            verseCount: quran.getVerseCount(suraNumber),
                            sorahIndex: suraNumberInQuran-1,
                            onReadPressed: () async{
                              CacheHelper.saveData(key: "lastRead", value: DateTime.now().toString());
                              cubit.stop();
                              await AudioServices().player.clearAudioSources();
                              cubit.soraNumber = suraNumber;
                              navigateTo(context, QuranViewPage(
                                shouldHighlightText: false,
                                highlightVerse: "",
                                jsonData: cubit.suraJsonData,
                                pageNumber: quran.getPageNumber(
                                  suraNumberInQuran,
                                  1,
                                ),
                              ),
                              );
                            },
                            onListenPressed: () {
                              AudioQuranCubit.get(context).sorahNumber = suraNumber;
                              cubit.soraNumber = suraNumber;
                              navigateTo(context, AudioScreen());
                            },
                          );
                        },
                        separatorBuilder: (context, index) => SizedBox(
                          height: 7.h,
                        ),
                        itemCount:cubit.filteredData!=null?cubit.filteredData!.length: 114),
                    if (cubit.ayatFiltered != null)
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount:
                        cubit.ayatFiltered["occurences"] > 10
                            ? 10
                            : cubit.ayatFiltered["occurences"],
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: GestureDetector(
                              onTap: () async {
                                cubit.stop();
                                await AudioServices().player.clearAudioSources();
                                cubit.soraNumber = cubit.ayatFiltered["result"][index]['surah'];
                                int verseNumber = cubit.ayatFiltered["result"][index]['verse'];
                                int pageNumber = quran.getPageNumber(cubit.soraNumber!, verseNumber);
                                navigateTo(context, QuranViewPage(
                                  shouldHighlightText: false,
                                  highlightVerse: "$verseNumber",
                                  jsonData: cubit.suraJsonData,
                                  pageNumber: pageNumber,
                                ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(
                                  8,
                                ), // optional, adjust as needed
                                decoration: BoxDecoration(
                                  color: Colors.white70,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  "سورة ${quran.getSurahNameArabic(cubit.ayatFiltered["result"][index]["surah"])} - ${quran.getVerse(cubit.ayatFiltered["result"][index]["surah"], cubit.ayatFiltered["result"][index]["verse"], verseEndSymbol: true)}",
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 17.sp,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                
                  ],
                ),
              ),
            )),
          );
        },
    );
  }
}
