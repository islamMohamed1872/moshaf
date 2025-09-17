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
    highlightVerseNotifier = ValueNotifier(widget.highlightVerse);

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
      highlightVerseNotifier.value = highlightVerseNotifier.value == null
          ? widget.highlightVerse
          : null;

      if (timer.tick >= 4) {
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

        spans.add(TextSpan(
          recognizer: MultiTapGestureRecognizer()
            ..onTap = (_) {
              TextQuranCubit.get(context).saveLastRead(
                page: pageIndex,
                verse: i,
                sora: widget.jsonData[getPageData(pageIndex)[0]["surah"] - 1]
                ["number"],
              );
              Fluttertoast.showToast(
                msg: "تم حفظ تقدمك بنجاح",
                toastLength: Toast.LENGTH_SHORT,
                backgroundColor: HexColor("d6bb97"),
                textColor: mainTextColor,
                gravity: ToastGravity.BOTTOM,
                fontSize: 16.0,
              );
            },
          text: i == e["start"]
              ? "${getVerseQCF(e["surah"], i).replaceAll(" ", "").substring(0, 1)}\u200A${getVerseQCF(e["surah"], i).replaceAll(" ", "").substring(1)}"
              : getVerseQCF(e["surah"], i).replaceAll(' ', ''),
          style: TextStyle(
            color: Colors.black,
            height: (pageIndex == 1 || pageIndex == 2) ? 2.h : 1.95.h,
            fontFamily: "QCF_P${pageIndex.toString().padLeft(3, "0")}",
            fontSize: (pageIndex == 1 || pageIndex == 2)
                ? 28.sp
                : (pageIndex == 145 ||
                pageIndex == 201 ||
                pageIndex == 532 ||
                pageIndex == 533)
                ? 22.4.sp
                : 23.1.sp,
            backgroundColor: Colors.transparent,
          ),
        ));
      }
    }

    final richText = RichText(
      textDirection: m.TextDirection.rtl,
      textAlign: TextAlign.center,
      softWrap: true,
      locale: const Locale("ar"),
      text: TextSpan(
        style: TextStyle(
          color: m.Colors.black,
          fontSize: 23.sp.toDouble(),
        ),
        children: spans,
      ),
    );

    _pageWidgetCache[pageIndex] = richText;
    return richText;
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
                    const SizedBox(height: 30),
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
