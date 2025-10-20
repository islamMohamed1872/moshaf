import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moshaf/components/audio_service.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_cubit.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_states.dart';
import 'package:moshaf/views/quran/tafseer_screen.dart';
import 'package:quran/quran.dart';
import 'package:quran/quran.dart' as quran;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../components/const.dart';
import '../widgets/basmallah.dart';
import '../widgets/header_widget.dart';

class QuranViewPage extends StatefulWidget {
  final int pageNumber;
  final dynamic jsonData;
  final bool shouldHighlightText;
  final dynamic highlightVerse;

  const QuranViewPage({
    Key? key,
    required this.pageNumber,
    required this.jsonData,
    required this.shouldHighlightText,
    required this.highlightVerse,
  }) : super(key: key);

  @override
  State<QuranViewPage> createState() => _QuranViewPageState();
}

class _QuranViewPageState extends State<QuranViewPage>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  late ValueNotifier<dynamic> highlightVerseNotifier;
  ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final Map<int, Widget> _pageWidgetCache = {};
  String selectedSpan = "";
  int index = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    index = widget.pageNumber;
    _pageController = PageController(initialPage: index);
    highlightVerseNotifier = ValueNotifier<int?>(
      int.tryParse(widget.highlightVerse ?? ''),
    );
    // print(highlightVerseNotifier.value);

    final player = AudioServices().player;
    player.playerStateStream.listen((state) {
      if (!mounted) return;
      isPlaying.value = state.playing;
    });

    // Only cache the starting page + ahead
    // load only the first visible font
    TextQuranCubit.get(context).loadQuranFontCached(index);

    // prefetch next 2-3 pages
    for (int i = index + 1; i <= index + 3; i++) {
      TextQuranCubit.get(context).loadQuranFontCached(i);
    }

    if (widget.shouldHighlightText) {
      // _startHighlightAnimation();
    }
  }

  @override
  void dispose() {
    highlightVerseNotifier.dispose();
    isPlaying.dispose();
    super.dispose();
  }

  void _startHighlightAnimation() {
    Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final int? verseAsInt = int.tryParse(
        widget.highlightVerse?.toString() ?? '',
      );

      highlightVerseNotifier.value =
          highlightVerseNotifier.value == null ? verseAsInt : null;

      if (timer.tick >= 7) {
        highlightVerseNotifier.value = null;
        timer.cancel();
      }
    });
  }

  int? _currentVerseIndex; // add this to your state class

  Future<void> playSurahVersesSequentially(List pageData) async {
    final player = AudioServices().player;

    // Flatten all verses for the page once
    final verses = <Map<String, int>>[];
    for (var e in pageData) {
      for (var i = e["start"]; i <= e["end"]; i++) {
        verses.add({"surah": e["surah"], "verse": i});
      }
    }

    // Initialize current verse index if not set
    _currentVerseIndex ??= 0;

    // If currently playing → pause
    if (isPlaying.value) {
      await player.pause();
      isPlaying.value = false;
      return;
    }

    // If paused → resume
    if (player.processingState == ProcessingState.ready &&
        player.position > Duration.zero &&
        _currentVerseIndex! < verses.length) {
      await player.play();
      isPlaying.value = true;
      return;
    }

    // Start fresh if finished or stopped
    await player.stop();
    _currentVerseIndex = 0;
    isPlaying.value = true;

    while (isPlaying.value && _currentVerseIndex! < verses.length) {
      final verse = verses[_currentVerseIndex!];
      final surah = verse["surah"]!;
      final ayah = verse["verse"]!;

      final url =
      quran.getAudioURLByVerse(surah, ayah, "ar.abdulbasitmurattal");

      if (mounted) highlightVerseNotifier.value = ayah;


      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: '$surah:$ayah',
            album: 'Quran',
            title: 'سورة ${getSurahNameArabic(surah)} - آية $ayah',
            artist: 'عبد الباسط عبد الصمد',
          ),
        ),
      );

      await player.play();

      // Wait until verse finishes or user pauses
      await player.processingStateStream.firstWhere(
            (state) => state == ProcessingState.completed || !isPlaying.value,
      );

      // If user paused mid-verse, break
      if (!isPlaying.value) break;

      // Move to next verse
      _currentVerseIndex = _currentVerseIndex! + 1;
    }

    // If finished all verses → reset
    if (_currentVerseIndex == verses.length) {
      _currentVerseIndex = 0;
      isPlaying.value = false;
      if (mounted) highlightVerseNotifier.value = null;
    }
  }


  /// Lazy cache: only build pages if they’re missing
  void _tryCacheAhead(int currentPage) {
    // Cache current if missing
    if (!_pageWidgetCache.containsKey(currentPage)) {
      _pageWidgetCache[currentPage] = _buildPageWidget(currentPage);
    }
    // Cache next 5 ahead if missing
    for (
      int i = currentPage + 1;
      i <= currentPage + 5 && i <= totalPagesCount;
      i++
    ) {
      if (!_pageWidgetCache.containsKey(i)) {
        _pageWidgetCache[i] = _buildPageWidget(i);
      }
    }
  }

  Widget _buildPageWidget(int pageIndex) {
    if (pageIndex <= 0) return SizedBox();
    if (_pageWidgetCache.containsKey(pageIndex)) {
      return _pageWidgetCache[pageIndex]!;
    }
    final pageData = getPageData(pageIndex);

    final widget2 = BlocBuilder<TextQuranCubit, TextQuranStates>(
      builder: (context, state) {
        final cubit = TextQuranCubit.get(context);
        return ValueListenableBuilder(
          valueListenable: highlightVerseNotifier,
          builder: (context, dynamic highlighted, _) {
            final spans = <InlineSpan>[];

            for (var e in pageData) {
              for (var i = e["start"]; i <= e["end"]; i++) {
                if (i == 1) {
                  // spans.add(WidgetSpan(
                  //   child: HeaderWidget(e: e, jsonData: widget.jsonData),
                  // ));
                  if (pageIndex != 187 && pageIndex != 1) {
                    spans.add(WidgetSpan(child: Basmallah(index: 0)));
                  }
                  if (pageIndex == 187) {
                    spans.add(WidgetSpan(child: SizedBox(height: 10.h)));
                  }
                }

                spans.add(
                  TextSpan(
                    recognizer:
                        TapGestureRecognizer()
                          ..onTapDown = (TapDownDetails details) async {
                            highlightVerseNotifier.value = i;

                            // Get the tap position relative to the overlay
                            final RenderBox overlay =
                                Overlay.of(context).context.findRenderObject()
                                    as RenderBox;
                            final Offset tapPosition = details.globalPosition;

                            // 🔹 Show popup menu at the tap position
                            final result = await showMenu<String>(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              color: Colors.white,
                              position: RelativeRect.fromLTRB(
                                tapPosition.dx,
                                tapPosition.dy,
                                overlay.size.width - tapPosition.dx,
                                overlay.size.height - tapPosition.dy,
                              ),
                              items: [
                                PopupMenuItem<String>(
                                  value: 'tafseer',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.menu_book_outlined,color: Colors.black,size: 15,),
                                      SizedBox(width: 6.w),
                                      Text(
                                        'تفسير',
                                        textDirection: TextDirection.rtl,
                                        style: AppTextStyles.madReg12(context,color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(height: 1,color: Color(0xffD6D6D6),),
                                PopupMenuItem<String>(
                                  value: 'save',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.bookmark_border,color: Colors.black,size: 15,),
                                      SizedBox(width: 6.w),
                                      Text(
                                        'حفظ الآيه',
                                        textDirection: TextDirection.rtl,
                                        style: AppTextStyles.madReg12(context,color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(height: 1,color: Color(0xffD6D6D6),),
                                PopupMenuItem<String>(
                                  value: 'play',
                                  child: Row(
                                    children: [
                                      const Icon(FontAwesomeIcons.circlePlay,color: Colors.black,size: 15,),
                                      SizedBox(width: 6.w),
                                      Text(
                                        'تشغيل',
                                        textDirection: TextDirection.rtl,
                                        style: AppTextStyles.madReg12(context,color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            // 🔹 Handle menu selection
                            if (result == 'save') {
                              cubit.saveLastRead(
                                page: pageIndex,
                                verse: i,
                                sora:
                                    widget.jsonData[getPageData(
                                          pageIndex,
                                        )[0]["surah"] -
                                        1]["number"],
                              );

                              Fluttertoast.showToast(
                                msg: " تم حفظ تقدمك بنجاح",
                                toastLength: Toast.LENGTH_SHORT,
                                backgroundColor: HexColor("d6bb97"),
                                textColor: mainTextColor,
                                gravity: ToastGravity.BOTTOM,
                                fontSize: 16.0,
                              );
                            } else if (result == 'tafseer')
                            {
                              cubit.getVerseTafseer(
                                sora:  widget.jsonData[getPageData(
                                  pageIndex,
                                )[0]["surah"] -
                                    1]["number"],
                                verse: i,
                              );
                              final tafseer = await cubit.stream
                                  .where((state) => state is GetVerseTafseerSuccessState)
                                  .map((state) => cubit.verseTafseer)
                                  .first;
                              if (context.mounted) {
                                navigateTo(context, TafseerScreen(ayah: i, tafseer: tafseer,sorah:  widget.jsonData[getPageData(
                                  pageIndex,
                                )[0]["surah"] -
                                    1]["number"],));
                                // navigateTo(context, TafseerScreen(ayah: Text(
                                //   getVerseQCF(
                                //     e["surah"],
                                //     i,
                                //   ).replaceAll(' ', ''),
                                //   style: TextStyle(
                                //     fontSize: 20,
                                //     color: Color(AppColors.mainGreen),
                                //     fontFamily:
                                //     "QCF_P${pageIndex.toString().padLeft(3, "0")}",
                                //   ),
                                //   textDirection: TextDirection.rtl,
                                // )
                                //     , tafseer: tafseer));
                                // showModalBottomSheet(
                                //   context: context,
                                //   backgroundColor: Colors.white,
                                //   shape: const RoundedRectangleBorder(
                                //     borderRadius: BorderRadius.vertical(
                                //       top: Radius.circular(20),
                                //     ),
                                //   ),
                                //   enableDrag: true,
                                //   builder: (context) {
                                //     return Padding(
                                //       padding: const EdgeInsets.all(16.0),
                                //       child: SingleChildScrollView(
                                //         child: Column(
                                //           mainAxisSize: MainAxisSize.min,
                                //           crossAxisAlignment:
                                //               CrossAxisAlignment.center,
                                //           children: [
                                //             Container(
                                //               width: 50,
                                //               height: 5,
                                //               margin: const EdgeInsets.only(
                                //                 bottom: 12,
                                //               ),
                                //               decoration: BoxDecoration(
                                //                 color: Colors.grey[400],
                                //                 borderRadius:
                                //                     BorderRadius.circular(2.5),
                                //               ),
                                //             ),
                                //             Text(
                                //               getVerseQCF(
                                //                 e["surah"],
                                //                 i,
                                //               ).replaceAll(' ', ''),
                                //               style: TextStyle(
                                //                 fontSize: 18,
                                //                 color: Colors.black,
                                //                 fontFamily:
                                //                     "QCF_P${pageIndex.toString().padLeft(3, "0")}",
                                //               ),
                                //               textDirection: TextDirection.rtl,
                                //             ),
                                //             const SizedBox(height: 12),
                                //             Text(
                                //               tafseer,
                                //               style: const TextStyle(
                                //                 fontSize: 16,
                                //                 height: 1.6,
                                //                 color: Colors.black87,
                                //               ),
                                //               textAlign: TextAlign.justify,
                                //               textDirection: TextDirection.rtl,
                                //             ),
                                //             const SizedBox(height: 20),
                                //           ],
                                //         ),
                                //       ),
                                //     );
                                //   },
                                // );
                              }
                            }
                            else if(result =="play"){
                              final player = AudioServices().player;
                              final url = quran.getAudioURLByVerse(e["surah"], i, "ar.abdulbasitmurattal");

                              await player.setAudioSource(
                                AudioSource.uri(
                                  Uri.parse(url),
                                  tag: MediaItem(
                                    id: 'verse_audio_${e["surah"]}_$i',
                                    album: 'Quran',
                                    title: 'سورة ${getSurahNameArabic(e["surah"])} - آية $i',
                                    artist: 'عبد الباسط عبد الصمد',
                                  ),
                                ),
                              );

                              isPlaying.value = true;
                              await player.play();

                              // 👇 Wait for verse to finish or stop
                              player.processingStateStream.firstWhere((state) =>
                              state == ProcessingState.completed ||
                                  !isPlaying.value).then((_) {
                                if (mounted) isPlaying.value = false;
                              });
                            }
                          },

                    text: getVerseQCF(e["surah"], i).replaceAll(' ', ''),
                    style: TextStyle(
                      color: Colors.white,
                      backgroundColor:
                          highlighted == i
                              ? HexColor("998300").withValues(alpha: 0.2)
                              : Colors.transparent,
                      fontFamily:
                          "QCF_P${pageIndex.toString().padLeft(3, "0")}",
                      fontSize: 23.sp,
                      height: 1.95.h,
                      wordSpacing: 20,
                    ),
                  ),
                );
              }
            }

            return RichText(
              textDirection: m.TextDirection.rtl,
              textAlign: TextAlign.center,
              text: TextSpan(children: spans),
            );
          },
        );
      },
    );

    _pageWidgetCache[pageIndex] = widget2;
    return widget2;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(AppColors.scaffoldBg),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.ltr, // Force LTR scrolling logic
          child: PageView.builder(
            controller: _pageController,
            reverse: true,
            scrollDirection: Axis.horizontal,
            allowImplicitScrolling: true,
            onPageChanged: (a) async{
              // TextQuranCubit.get(context).soraNumber = widget.jsonData[getPageData(
              //   a,
              // )[0]["surah"]]['number'];
              // print(widget.jsonData[getPageData(
              //   a-1,
              // )[0]["surah"]]);
              selectedSpan = "";
              index = a;
              if (index <= 0) return;
              await AudioServices().player.stop();
              isPlaying.value = false;
              if(highlightVerseNotifier.value!=null) highlightVerseNotifier.value=null;
              _tryCacheAhead(index);
              // load font for this page + next couple
              TextQuranCubit.get(context).loadQuranFontCached(index);
              for (int i = index + 1; i <= index + 3; i++) {
                TextQuranCubit.get(context).loadQuranFontCached(i);
              }
            },
            itemCount: totalPagesCount + 1,
            itemBuilder: (context, pageIndex) {
              if (pageIndex == 0) {
                return Container(
                  color: const Color(0xffFFFCE7),
                  child: Image.asset(
                    "assets/images/mostakeem_logo.png",
                    fit: BoxFit.contain,
                  ),
                );
              }

              return Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: Image.asset(
                      "assets/images/quran_bg.png",
                      // fit: BoxFit.fitHeight,
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                      right: 0,
                      left: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            TextQuranCubit.get(context).convertToArabic(pageIndex.toString()),
                            style: AppTextStyles.madMd14(context,color: Colors.white),
                          ),
                        ],
                      )
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () async{
                                  await AudioServices().player.clearAudioSources();
                                  TextQuranCubit.get(context).stop();
                                  isPlaying.value = false;
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  width: 30.w,
                                  height: 30.w,
                                  padding: EdgeInsetsDirectional.only(
                                    start: 7.w,
                                    top: 5,
                                    bottom: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(AppColors.containerBorders),
                                    ),
                                  ),
                                  child: const FittedBox(
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: HeaderWidget(
                                  e:
                                      widget.jsonData[getPageData(
                                        pageIndex,
                                      )[0]["surah"]],
                                  jsonData: widget.jsonData,
                                ),
                              ),
                              // Container(
                              //   height: 20,
                              //   width: 120,
                              //   decoration: BoxDecoration(
                              //     color: Colors.orange.withOpacity(0.5),
                              //     borderRadius: BorderRadius.circular(12),
                              //     border: Border.all(color: Colors.black),
                              //   ),
                              //   child: Center(
                              //     child: Text(
                              //       "الصفحه $pageIndex",
                              //       style: const TextStyle(
                              //         fontFamily: 'aldahabi',
                              //         fontSize: 12,
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              ValueListenableBuilder<bool>(
                                valueListenable: isPlaying,
                                builder: (context, playing, _) {
                                  return InkWell(
                                    onTap: () async {
                                      final pageData = getPageData(index);
                                      await playSurahVersesSequentially(pageData);
                                    },
                                    child: Icon(
                                      playing ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                                      size: 20.w,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          if (pageIndex == 1 || pageIndex == 2)
                            SizedBox(height: screenSize.height * .15),

                          // SizedBox(height: 15.h),
                          Directionality(
                            textDirection: m.TextDirection.rtl,
                            child: SizedBox(
                              width: double.infinity,
                              child:
                                  BlocBuilder<TextQuranCubit, TextQuranStates>(
                                    builder:
                                        (context, state) => Transform.scale(
                                          scale: 0.95,
                                          alignment: Alignment.topCenter,
                                          child: Skeletonizer(
                                            enabled:
                                                !TextQuranCubit.get(
                                                  context,
                                                ).isFontLoaded(pageIndex),
                                            child: _buildPageWidget(pageIndex),
                                          ),
                                        ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
