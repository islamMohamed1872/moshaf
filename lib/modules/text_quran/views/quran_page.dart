import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_cubit.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_states.dart';
import 'package:quran/quran.dart';
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
  print(highlightVerseNotifier.value);

    // Only cache the starting page + ahead
    // load only the first visible font
    TextQuranCubit.get(context).loadQuranFontCached(index);

    // prefetch next 2-3 pages
    for (int i = index + 1; i <= index + 3; i++) {
      TextQuranCubit.get(context).loadQuranFontCached(i);
    }

    if (widget.shouldHighlightText) {
      _startHighlightAnimation();
    }
  }

  @override
  void dispose() {
    highlightVerseNotifier.dispose();
    super.dispose();
  }

  void _startHighlightAnimation() {
    Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final int? verseAsInt = int.tryParse(widget.highlightVerse?.toString() ?? '');

      highlightVerseNotifier.value = highlightVerseNotifier.value == null
          ? verseAsInt
          : null;

      if (timer.tick >= 7) {
        highlightVerseNotifier.value = null;
        timer.cancel();
      }
    });
  }


  /// Lazy cache: only build pages if they’re missing
  void _tryCacheAhead(int currentPage) {
    // Cache current if missing
    if (!_pageWidgetCache.containsKey(currentPage)) {
      _pageWidgetCache[currentPage] = _buildPageWidget(currentPage);
    }
    // Cache next 5 ahead if missing
    for (int i = currentPage + 1;
    i <= currentPage + 5 && i <= totalPagesCount;
    i++) {
      if (!_pageWidgetCache.containsKey(i)) {
        _pageWidgetCache[i] = _buildPageWidget(i);
      }
    }
  }

  Widget _buildPageWidget(int pageIndex) {
    if (_pageWidgetCache.containsKey(pageIndex)) {
      return _pageWidgetCache[pageIndex]!;
    }

    final pageData = getPageData(pageIndex);

    final widget2 = BlocBuilder<TextQuranCubit,TextQuranStates>(
      builder:  (context, state) {
        final cubit = TextQuranCubit.get(context);
        return ValueListenableBuilder(
          valueListenable: highlightVerseNotifier,
          builder: (context, dynamic highlighted, _) {
            final spans = <InlineSpan>[];

            for (var e in pageData) {
              for (var i = e["start"]; i <= e["end"]; i++) {
                if (i == 1) {
                  spans.add(WidgetSpan(
                    child: HeaderWidget(e: e, jsonData: widget.jsonData),
                  ));
                  if (pageIndex != 187 && pageIndex != 1) {
                    spans.add(WidgetSpan(child: Basmallah(index: 0)));
                  }
                  if (pageIndex == 187) {
                    spans.add(WidgetSpan(child: SizedBox(height: 10.h)));
                  }
                }

                spans.add(
                  TextSpan(
                    recognizer: TapGestureRecognizer()
                      ..onTapDown = (TapDownDetails details) async {
                        highlightVerseNotifier.value = i;
                        final cubit = TextQuranCubit.get(context);

                        // Get the tap position relative to the overlay
                        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                        final Offset tapPosition = details.globalPosition;

                        // 🔹 Show popup menu at the tap position
                        final result = await showMenu<String>(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          color: mainBackgroundColor,
                          position: RelativeRect.fromLTRB(
                            tapPosition.dx,
                            tapPosition.dy,
                            overlay.size.width - tapPosition.dx,
                            overlay.size.height - tapPosition.dy,
                          ),
                          items: [
                            PopupMenuItem<String>(
                              value: 'save',
                              child: Row(
                                children: [
                                  const Icon(Icons.bookmark_border),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'حفظ التقدم',
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontFamily: "nabi",
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'tafseer',
                              child: Row(
                                children: [
                                  const Icon(Icons.menu_book_outlined),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'عرض التفسير',
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontFamily: "nabi",
                                      fontSize: 15.sp,
                                    ),
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
                            sora: widget.jsonData[getPageData(pageIndex)[0]["surah"] - 1]["number"],
                          );

                          Fluttertoast.showToast(
                            msg: " تم حفظ تقدمك بنجاح",
                            toastLength: Toast.LENGTH_SHORT,
                            backgroundColor: HexColor("d6bb97"),
                            textColor: mainTextColor,
                            gravity: ToastGravity.BOTTOM,
                            fontSize: 16.0,
                          );
                        } else if (result == 'tafseer') {
                           await cubit.getVerseTafseer(
                            sora: cubit.soraNumber!,
                            verse: i,
                          );

                          if (context.mounted) {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              enableDrag: true,
                              builder: (context) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 5,
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[400],
                                            borderRadius: BorderRadius.circular(2.5),
                                          ),
                                        ),
                                        Text(
                                          getVerseQCF(e["surah"], i).replaceAll(' ', ''),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontFamily:
                                            "QCF_P${pageIndex.toString().padLeft(3, "0")}",
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          cubit.verseTafseer,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            height: 1.6,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.justify,
                                          textDirection: TextDirection.rtl,
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        }
                      },

                    text: getVerseQCF(e["surah"], i).replaceAll(' ', ''),
                    style: TextStyle(
                      color: Colors.black,
                      backgroundColor: highlighted == i ? HexColor("d6bb97") : Colors.transparent,
                      fontFamily: "QCF_P${pageIndex.toString().padLeft(3, "0")}",
                      fontSize: 23.sp,
                      height: 1.95.h,
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
      backgroundColor: HexColor("fffaf5"),
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          reverse: true,
          scrollDirection: Axis.horizontal,
          allowImplicitScrolling: true,
          onPageChanged: (a) {
            selectedSpan = "";
            index = a;
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
                child: Image.asset("assets/images/jpg", fit: BoxFit.fill),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios, size: 24),
                        ),
                        Container(
                          height: 20,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Center(
                            child: Text(
                              "الصفحه $pageIndex",
                              style: const TextStyle(
                                fontFamily: 'aldahabi',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          widget.jsonData[getPageData(pageIndex)[0]["surah"] - 1]
                          ["name"],
                          style: const TextStyle(
                            fontFamily: "Taha",
                            fontSize: 14,
                          ),
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
                        child: BlocBuilder<TextQuranCubit,TextQuranStates>(
                          builder:(context, state) =>  Skeletonizer(
                              enabled: !TextQuranCubit.get(context).isFontLoaded(pageIndex),
                              child: _buildPageWidget(pageIndex)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
