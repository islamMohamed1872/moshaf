import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/components/components.dart';

// import 'package:quran/dart';
import 'package:quran/quran.dart';
import 'package:string_validator/string_validator.dart';
import 'package:quran/quran.dart' as quran;

import '../../controllers/text_quran/text_quran_cubit.dart';
import '../../controllers/text_quran/text_quran_states.dart';
import '../quran/widgets/quran_page.dart';


class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextQuranCubit,TextQuranStates>(
      builder: (context, state) {
        final cubit = TextQuranCubit.get(context);
        return Scaffold(
          backgroundColor: HexColor("fffaf5"),
          body:
          cubit.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                physics: const ClampingScrollPhysics(),
                children: [
                  Container(
                    width: double.infinity,
                    height: 45.h,
                    decoration: BoxDecoration(
                      color: HexColor("FDEDDC"),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: TextFormField(
                        cursorColor: Colors.black,
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
                          hintText: 'بحث',
                          hintStyle: TextStyle(color: HexColor("333333")),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder:
                        (context, index) => Padding(
                      padding: const EdgeInsetsDirectional.only(top: 10.0, bottom: 10.0),
                      child: Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    itemCount:cubit.searchController.text.isNotEmpty?
                    min(7, cubit.filteredData!.length):
                    cubit.homeCount,
                    itemBuilder: (context, index) {

                      if(cubit.filteredData!.isNotEmpty){
                        int suraNumber = index + 1;
                        String suraName = cubit.filteredData![index]["englishName"];
                        int suraNumberInQuran = cubit.filteredData![index]["number"];
                        return Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: ListTile(
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
                                      cubit.convertToArabic(suraNumberInQuran.toString()),
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
                              suraName,
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
                                  "${quran.getVerseCount(suraNumber).toString()} ايات ",
                                  textDirection: TextDirection.rtl,
                                  style:  TextStyle(
                                    color: HexColor("936f35"),
                                    fontSize: 14.sp,
                                  ),
                                ),
                                Text(
                                  quran.getPlaceOfRevelation(
                                      suraNumber) ==
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
                                text: cubit.filteredData![index]['number'].toString(),
                                style:  TextStyle(
                                  fontFamily: "arsura",
                                  fontSize: 30.sp,
                                  color: HexColor("936f35"),
                                ),
                              ),
                            ),
                            onTap: () {
                              cubit.soraNumber = suraNumberInQuran;
                              navigateTo(context, QuranViewPage(
                                shouldHighlightText: false,
                                highlightVerse: "",
                                jsonData: cubit.suraJsonData,
                                pageNumber: getPageNumber(
                                  suraNumberInQuran,
                                  1,
                                ),
                              ),
                              );
                            },
                          ),
                        );

                      }
                      return SizedBox();
                    },
                  ),
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
                              // Your onTap logic here
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
                                "سورة ${getSurahNameArabic(cubit.ayatFiltered["result"][index]["surah"])} - ${getVerse(cubit.ayatFiltered["result"][index]["surah"], cubit.ayatFiltered["result"][index]["verse"], verseEndSymbol: true)}",
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
                  if(cubit.homeCount!=114&&cubit.searchController.text.isEmpty)
                    Align(
                      alignment: Alignment.center, // or Alignment.centerLeft / Right
                      child: SizedBox(
                        width: 80.w,
                        child: MaterialButton(
                          height: 30,
                          color: HexColor("#795546"),
                          onPressed: ()async {
                            cubit.loadMore();
                            // await FlutterOverlayWindow.showOverlay(
                            //   height: 500,
                            //   width: 500,
                            //   alignment: OverlayAlignment.center,
                            //   enableDrag: false,
                            // );

                            // // Auto-close after 2 seconds
                            // Future.delayed(Duration(seconds: 2), () {
                            //   FlutterOverlayWindow.closeOverlay();
                            // });
                          },
                          child: Text(
                            "المزيد",
                            style: TextStyle(
                              fontFamily: "nabi",
                              color: HexColor("#f3eee7"),
                              fontSize: 17.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 80.h,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

