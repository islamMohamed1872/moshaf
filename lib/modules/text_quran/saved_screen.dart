import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/components/const.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_cubit.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_states.dart';
import 'package:moshaf/modules/text_quran/views/quran_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quran/quran.dart' as quran;

import '../../components/components.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final mediaQuery = MediaQuery.of(context);
    return BlocConsumer<TextQuranCubit, TextQuranStates>(
      builder: (context, state) {
        final cubit = TextQuranCubit.get(context);
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: ()async {
                         //

                        // if (await FlutterOverlayWindow.isPermissionGranted()) {
                        //   if (await FlutterOverlayWindow.isActive()) {
                        //     await FlutterOverlayWindow.closeOverlay();
                        //   }
                        //
                        //
                        //   await FlutterOverlayWindow.showOverlay(
                        //     enableDrag: true,
                        //     flag: OverlayFlag.defaultFlag,
                        //     alignment: OverlayAlignment.centerRight,
                        //     visibility: NotificationVisibility.visibilityPublic,
                        //   );
                        //
                        //   Future.delayed(const Duration(seconds: 5), () async {
                        //     await FlutterOverlayWindow.closeOverlay();
                        //   });
                        // }

                        // if (cubit.sorahNumber > 0) {
                        //
                        //   // 2. Populate the sorahPages list based on the loaded sorahNumber
                        //   cubit.sorahPages = quran.getSurahPages(cubit.sorahNumber);
                        //   // 3. Now that the state is fully prepared, navigate.
                        //   // navigateTo(
                        //   //   context,
                        //   //   SorahTextScreen(
                        //   //     // Pass the cubit instance to the next screen
                        //   //     context1: context,
                        //   //     // The rest of these parameters are based on the cubit's state
                        //   //     soraNumber: cubit.sorahNumber,
                        //   //     place: quran.getPlaceOfRevelation(cubit.sorahNumber) == "Makkah"
                        //   //         ? "مكية"
                        //   //         : "مدنية",
                        //   //     verses: quran.getVerseCount(cubit.sorahNumber),
                        //   //     arabicName: quran.getSurahNameArabic(cubit.sorahNumber),
                        //   //     englishName: quran.getSurahName(cubit.sorahNumber),
                        //   //     number: cubit.sorahNumber,
                        //   //   ),
                        //   // );
                        // }
                        // else {
                        //   // Optional: Show a message if there's no saved data yet.
                        //   ScaffoldMessenger.of(context).showSnackBar(
                        //     SnackBar(content: Text('لا توجد بيانات محفوظة بعد')),
                        //   );
                        // }
                      },
                      child: Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            stops: [0.0, 0.4, 0.7, 1.0],
                            colors: [
                              Color(0xFFF5EDE3), // soft ivory-beige
                              Color(0xFFEADBC8), // light sand
                              Color(0xFFD4BBA0), // warm tan
                              Color(0xFFB89C7A), // deep golden brown
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB89C7A).withOpacity(0.35),
                              spreadRadius: 1,
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          image: DecorationImage(
                            image: const AssetImage("assets/images/pray.png"),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.white.withOpacity(
                                0.08,
                              ), // subtle pattern overlay
                              BlendMode.dstATop,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: ConditionalBuilder(
                            condition:
                                state is! GetSharedPreferencesLoadingState,
                            builder:
                                (context) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "اخر قراءه",
                                      style: TextStyle(
                                        color: mainTextColor,
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                            55,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.005,
                                    ),
                                    cubit.savedSora == 0
                                        ? _buildShimmerLine(
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.2,
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.02,
                                        )
                                        : RichText(
                                      text: TextSpan(
                                        text: cubit.savedSora.toString(),
                                        style:  TextStyle(
                                          fontFamily: "arsura",
                                          fontSize: 35.sp,
                                          color: mainTextColor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.005,
                                    ),
                                    cubit.savedPage == 0
                                        ? _buildShimmerLine(
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.4,
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.013,
                                        )
                                        : Row(
                                      spacing: 10,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              "رقم الاية: ${cubit.convertToArabic(cubit.savedVerse.toString())}",
                                              style: TextStyle(
                                                color: mainTextColor,
                                                fontSize:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height /
                                                    53,
                                              ),
                                            ),
                                            Text(
                                              "رقم الصفحه: ${cubit.convertToArabic(cubit.savedPage.toString())}",
                                              style: TextStyle(
                                                color: mainTextColor,
                                                fontSize:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.height /
                                                    53,
                                              ),
                                            ),
                                          ],
                                        ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.005,
                                    ),
                                    cubit.savedSora == "0"
                                        ? _buildShimmerLine(
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.11,
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.012,
                                        )
                                        :
                                    GestureDetector(
                                      onTap: () {
                                        navigateTo(context, QuranViewPage(
                                          shouldHighlightText: false,
                                          highlightVerse: "",
                                          jsonData: cubit.suraJsonData,
                                          pageNumber: quran.getPageNumber(
                                            cubit.savedSora,
                                            cubit.savedVerse,
                                          ),
                                        ),
                                        );
                                      },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Icon(
                                                Icons.arrow_back_ios_new_outlined,
                                                size:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.height /
                                                    53,
                                                color: mainTextColor,
                                              ),
                                              Text(
                                                "اذهب",
                                                style: TextStyle(
                                                  color: mainTextColor,
                                                  fontSize:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.height /
                                                      53,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  ],
                                ),
                            fallback: (context) => Container(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.sp),
                    Center(
                      child: Text(
                        "قال رَسُولَ اللَّهِ  ﷺ",
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: "nabi",
                          height: 2,
                          wordSpacing: 2,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.sp),
                    Text(
                      "اقْرَءُوا الْقُرْآنَ فَإِنَّهُ يَأْتِي يَوْمَ الْقِيَامَةِ شَفِيعًا لأصْحَابِه",
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: "nabi",
                        height: 2,
                        wordSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 20.sp),
                    Center(
                      child: Text(
                        "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: "nabi",
                          height: 2,
                          wordSpacing: 2,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.sp),
                    Text(
                      "﴿ وَقَالَ الرَّسُولُ يَا رَبِّ إِنَّ قَوْمِي اتَّخَذُوا هَذَا الْقُرْآنَ مَهْجُورًا ﴾",
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: "nabi",
                        height: 2,
                        wordSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "﴿ وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ فَهَلْ مِنْ مُدَّكِرٍ ﴾",
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: "nabi",
                        height: 2,
                        wordSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      listener: (context, state) {},
    );
  }

  // Helper shimmer builder
}

Widget _buildShimmerLine({required double width, required double height}) {
  return Shimmer.fromColors(
    baseColor: Colors.grey.withOpacity(0.4),
    highlightColor: Colors.white.withOpacity(0.4),
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20.0),
      ),
    ),
  );
}
