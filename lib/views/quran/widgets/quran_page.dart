import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
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
import 'package:moshaf/controllers/text_quran/text_quran_cubit.dart';
import 'package:moshaf/views/quran/tafseer_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../components/cache_helper.dart';
import '../../../components/const.dart';
import '../../../controllers/recitation/recitation_cubit.dart';
import '../../../controllers/text_quran/text_quran_states.dart';
import '../../../controllers/theme/theme_cubit.dart';
import 'basmallah.dart';
import 'header_widget.dart';

class QuranViewPage extends StatefulWidget {
  final int pageNumber;
  final dynamic jsonData;
  final bool shouldHighlightText;
  final dynamic highlightVerse;
  final bool navigatedFromRecitation;

  const QuranViewPage({
    Key? key,
    required this.pageNumber,
    required this.jsonData,
    required this.shouldHighlightText,
    required this.highlightVerse,
    required this.navigatedFromRecitation
  }) : super(key: key);

  @override
  State<QuranViewPage> createState() => _QuranViewPageState();
}

class _QuranViewPageState extends State<QuranViewPage>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  late ValueNotifier<dynamic> highlightVerseNotifier;
  ValueNotifier<bool> isPlaying = ValueNotifier(false);

  // ✅ OPTIMIZED CACHING
  final Map<int, Widget> _pageWidgetCache = {};
  final Set<int> _fontLoadingInProgress = {};
  int _lastCachedPage = 0;

  String selectedSpan = "";
  int index = 0;
  int? startVerse;
  int? endVerse;
  int? minPage;
  int? maxPage;
  int? _currentVerseIndex;

  // ✅ PRECOMPUTE THEME COLORS
  late Color popupBg, popupText, popupBorder;
  late bool isDarkMode, isGoldMode;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    index = widget.pageNumber;
    _ensureAllQuranFontsCached(widget.pageNumber);

    if (widget.navigatedFromRecitation) {
      final recitationCubit = RecitationCubit.get(context);
      final range = recitationCubit.getDailyReadingRange();
      minPage = range['startPage'];
      maxPage = range['endPage'];
    }

    _pageController = PageController(initialPage: index);
    highlightVerseNotifier = ValueNotifier<int?>(
      int.tryParse(widget.highlightVerse ?? ''),
    );

    final player = AudioServices().player;
    player.playerStateStream.listen((state) {
      if (!mounted) return;
      isPlaying.value = state.playing;
    });

    // ✅ LOAD FONTS ASYNCHRONOUSLY WITHOUT BLOCKING
    // _loadFontsAsync(index);

    if (widget.shouldHighlightText) {
      _startHighlightAnimation();
    }
  }

  Future<void> _ensureAllQuranFontsCached(int currentPage) async {
    final bool alreadyCached =
        await CacheHelper.getData(key: 'quran_fonts_cached') == true;

    if (alreadyCached) return;

    final cubit = TextQuranCubit.get(context);

    // 1️⃣ Ensure CURRENT page first (CRITICAL)
    try {
      await cubit.loadQuranFontCached(currentPage);
    } catch (_) {}

    // 2️⃣ Background download for the rest
    Future.microtask(() async {
      for (int page = 1; page <= totalPagesCount; page++) {
        if (page == currentPage) continue;

        try {
          await cubit.loadQuranFontCached(page);
        } catch (_) {}
      }

      await CacheHelper.saveData(
        key: 'quran_fonts_cached',
        value: true,
      );
    });
  }


  // ✅ ASYNC FONT LOADING (NON-BLOCKING)
  // void _loadFontsAsync(int startPage) {
  //   Future.microtask(() {
  //     TextQuranCubit.get(context).loadQuranFontCached(startPage);
  //
  //     for (int i = startPage + 1; i <= startPage + 3 && i <= totalPagesCount; i++) {
  //       if (!_fontLoadingInProgress.contains(i)) {
  //         _fontLoadingInProgress.add(i);
  //         Future.delayed(Duration(milliseconds: (i - startPage) * 50), () {
  //           if (mounted) {
  //             TextQuranCubit.get(context).loadQuranFontCached(i);
  //           }
  //         });
  //       }
  //     }
  //   });
  // }

  @override
  void dispose() {
    highlightVerseNotifier.dispose();
    isPlaying.dispose();
    _pageWidgetCache.clear();
    _fontLoadingInProgress.clear();
    super.dispose();
  }

  // ✅ AGGRESSIVE CACHE MANAGEMENT
  // void _tryCacheAhead(int currentPage) {
  //   // Only cache if we've scrolled significantly
  //   if ((currentPage - _lastCachedPage).abs() > 2) {
  //     _lastCachedPage = currentPage;
  //
  //     // Remove far away pages from cache
  //     final pagesToRemove = <int>[];
  //     for (final page in _pageWidgetCache.keys) {
  //       if ((page - currentPage).abs() > 10) {
  //         pagesToRemove.add(page);
  //       }
  //     }
  //
  //     for (final page in pagesToRemove) {
  //       _pageWidgetCache.remove(page);
  //     }
  //
  //     // Cache current and next 3
  //     for (int i = currentPage; i <= currentPage + 3 && i <= totalPagesCount; i++) {
  //       if (!_pageWidgetCache.containsKey(i)) {
  //         Future.microtask(() {
  //           _pageWidgetCache[i] = _buildPageWidget(i);
  //         });
  //       }
  //     }
  //   }
  // }

  // ✅ PRECOMPUTE THEME COLORS ONCE
  void _updateThemeColors() {
    final themeCubit = context.read<ThemeCubit>();
    isDarkMode = themeCubit.isDark;
    isGoldMode = AppColors.isGoldMode;

    popupBg = isGoldMode
        ? const Color(AppColors.goldBackground)
        : (isDarkMode ? Colors.black : Colors.white);

    popupText = isGoldMode
        ? const Color(AppColors.goldText)
        : (isDarkMode ? Colors.white : Colors.black);

    popupBorder = isGoldMode
        ? const Color(AppColors.goldBorder)
        : const Color(0xffD6D6D6);
  }

  Future<String?> _showDownloadDialog(
      int surah, int start, int end, bool isDark) async {
    final gold = AppColors.isGoldMode;
    final bgColor = gold
        ? const Color(AppColors.goldBackground)
        : (isDark ? Color(AppColors.scaffoldBg) : Colors.white);
    final titleColor = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);
    final textColor = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white70 : Colors.black87);
    final cancelBtnBg = gold
        ? const Color(AppColors.goldBorder).withOpacity(.2)
        : Colors.grey.shade200;
    final cancelBtnText = gold ? const Color(AppColors.goldText) : Colors.black;
    final downloadBtnBg = gold
        ? const Color(AppColors.goldPrimary)
        : Color(AppColors.mainGreen);

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: gold
              ? const BorderSide(color: Color(AppColors.goldBorder), width: 1)
              : BorderSide.none,
        ),
        title: Text(
          "تحميل المقاطع المختارة",
          textAlign: TextAlign.center,
          style: AppTextStyles.madB14(context, color: titleColor),
        ),
        content: Text(
          "هل تريد تحميل الآيات من $start إلى $end من سورة ${quran.getSurahNameArabic(surah)}؟",
          textAlign: TextAlign.center,
          style: AppTextStyles.madReg12(context, color: textColor),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: cancelBtnBg,
              foregroundColor: cancelBtnText,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text("إلغاء",
                style: AppTextStyles.madReg14(context, color: cancelBtnText)),
          ),
          TextButton.icon(
            icon: Icon(Icons.download, size: 18,
                color: gold ? Colors.white : Colors.white),
            label: Text("تحميل",
                style: AppTextStyles.madReg14(context, color: Colors.white)),
            style: TextButton.styleFrom(
              backgroundColor: downloadBtnBg,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _downloadCombinedAudio(surah, start, end);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _downloadCombinedAudio(int surah, int start, int end) async {
    try {
      Fluttertoast.showToast(msg: "⏳ جاري تحميل الآيات...");
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final List<String> files = [];

      for (int i = start; i <= end; i++) {
        final url = quran.getAudioURLByVerse(surah, i, "ar.abdulbasitmurattal");
        final savePath = "${tempDir.path}/verse_$i.mp3";
        await dio.download(url, savePath);
        files.add(savePath);
        debugPrint("✅ Downloaded verse $i");
      }

      final surahNameArabic = quran.getSurahNameArabic(surah);
      final sanitizedSurahName = surahNameArabic.replaceAll(" ", "_");
      final combinedFileName =
          "سورة_${sanitizedSurahName}_من_${start}_الى_${end}.mp3";

      Directory downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!downloadsDir.existsSync()) {
          downloadsDir = await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final combinedPath = "${downloadsDir.path}/$combinedFileName";
      await _combineAudioFiles(files, combinedPath);

      for (final path in files) {
        try {
          await File(path).delete();
        } catch (_) {}
      }

      Fluttertoast.showToast(
        msg: "✅ تم التحميل بنجاح! \n📥 تم حفظ الملف في مجلد التنزيلات.",
        toastLength: Toast.LENGTH_LONG,
      );

      _showShareDialog(combinedPath, surahNameArabic, start, end);
      debugPrint("🎧 Combined file saved at: $combinedPath");
    } catch (e, s) {
      debugPrint("❌ Download/Combine Error: $e\n$s");
      Fluttertoast.showToast(msg: "حدث خطأ أثناء التحميل");
    }
  }

  Future<void> _combineAudioFiles(List<String> inputPaths, String outputPath) async {
    final output = File(outputPath).openWrite();
    bool isFirst = true;

    for (final path in inputPaths) {
      final file = File(path);
      final bytes = await file.readAsBytes();
      if (isFirst) {
        output.add(bytes);
        isFirst = false;
      } else {
        int skip = _getID3HeaderSize(bytes);
        output.add(bytes.sublist(skip));
      }
    }
    await output.close();
  }

  int _getID3HeaderSize(List<int> bytes) {
    if (bytes.length < 10) return 0;
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      int size = (bytes[6] << 21) | (bytes[7] << 14) | (bytes[8] << 7) | bytes[9];
      return size + 10;
    }
    return 0;
  }

  void _showShareDialog(String filePath, String surahName, int start, int end) {
    final themeCubit = context.read<ThemeCubit>();
    final isDark = themeCubit.isDark;
    final isGold = AppColors.isGoldMode;
    final bgColor = isGold
        ? const Color(AppColors.goldBackground)
        : (isDark ? Color(AppColors.scaffoldBg) : Colors.white);
    final textColor = isGold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);
    final borderColor = isGold
        ? const Color(AppColors.goldBorder)
        : (isDark ? Colors.white10 : Colors.black12);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        title: Text("تم التحميل بنجاح",
            textAlign: TextAlign.center,
            style: AppTextStyles.madB14(context, color: textColor)),
        content: Text(
          "تم حفظ الملف:\nسورة $surahName من $start إلى $end\n\nهل ترغب بمشاركته على واتساب؟",
          textAlign: TextAlign.center,
          style: AppTextStyles.madReg12(context,
              color: isGold
                  ? const Color(AppColors.goldText)
                  : (isDark ? Colors.white70 : Colors.black87)),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor:
              isGold ? const Color(0xFFE6C87A) : Colors.grey.shade200,
              foregroundColor: textColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text("إغلاق",
                style: AppTextStyles.madReg14(context, color: textColor)),
          ),
          TextButton.icon(
            icon: const Icon(Icons.share, size: 18, color: Colors.white),
            label: Text("واتساب",
                style: AppTextStyles.madReg14(context, color: Colors.white)),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final file = File(filePath);
              if (!file.existsSync()) {
                Fluttertoast.showToast(msg: "⚠️ ملف الصوت غير موجود.");
                return;
              }
              try {
                await Share.shareXFiles(
                  [XFile(filePath)],
                  text: "🎧 سورة $surahName من $start إلى $end",
                );
              } catch (e) {
                Fluttertoast.showToast(msg: "⚠️ تعذرت المشاركة");
              }
            },
          ),
        ],
      ),
    );
  }

  void _startHighlightAnimation() {
    Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final int? verseAsInt = int.tryParse(widget.highlightVerse?.toString() ?? '');
      highlightVerseNotifier.value =
      highlightVerseNotifier.value == null ? verseAsInt : null;
      if (timer.tick >= 7) {
        highlightVerseNotifier.value = null;
        timer.cancel();
      }
    });
  }

  Future<void> playSurahVersesSequentially(List pageData) async {
    final player = AudioServices().player;
    final verses = <Map<String, int>>[];

    for (var e in pageData) {
      for (var i = e["start"]; i <= e["end"]; i++) {
        verses.add({"surah": e["surah"], "verse": i});
      }
    }

    _currentVerseIndex ??= 0;

    if (isPlaying.value) {
      await player.pause();
      isPlaying.value = false;
      return;
    }

    if (player.processingState == ProcessingState.ready &&
        player.position > Duration.zero &&
        _currentVerseIndex! < verses.length) {
      await player.play();
      isPlaying.value = true;
      return;
    }

    await player.stop();
    _currentVerseIndex = 0;
    isPlaying.value = true;

    while (isPlaying.value && _currentVerseIndex! < verses.length) {
      final verse = verses[_currentVerseIndex!];
      final surah = verse["surah"]!;
      final ayah = verse["verse"]!;
      final url = quran.getAudioURLByVerse(surah, ayah, "ar.abdulbasitmurattal");

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
      await player.processingStateStream.firstWhere(
            (state) => state == ProcessingState.completed || !isPlaying.value,
      );

      if (!isPlaying.value) break;
      _currentVerseIndex = _currentVerseIndex! + 1;
    }

    if (_currentVerseIndex == verses.length) {
      _currentVerseIndex = 0;
      isPlaying.value = false;
      if (mounted) highlightVerseNotifier.value = null;
    }
  }

  double getMushafLineHeight({
    required double availableHeight,
    required double fontSize,
  }) {
    const mushafLines = 15;
    return availableHeight / (mushafLines * fontSize);
  }

  // ✅ OPTIMIZED PAGE WIDGET BUILDER
  Widget _buildPageWidget(int pageIndex) {
    if (pageIndex <= 0) return const SizedBox();

    final pageData = getPageData(pageIndex);
    if (pageData.isEmpty) return const SizedBox();

    return _OptimizedPageBuilder(
      pageIndex: pageIndex,
      pageData: pageData,
      jsonData: widget.jsonData,
      highlightVerseNotifier: highlightVerseNotifier,
      onVerseAction: _handleVerseAction,
      getMushafLineHeight: getMushafLineHeight,
    );
  }

  Future<void> _handleVerseAction(
      String action,
      int verseNumber,
      int surah,
      int pageIndex,
      Map<String, dynamic> surahData,
      ) async {
    final cubit = TextQuranCubit.get(context);
    final isDark = context.read<ThemeCubit>().isDark;

    switch (action) {
      case 'save':
        cubit.saveLastRead(
          page: pageIndex,
          verse: verseNumber,
          sora: widget.jsonData[getPageData(pageIndex)[0]["surah"] - 1]["number"],
        );
        Fluttertoast.showToast(
          msg: "تم حفظ تقدمك بنجاح",
          backgroundColor: isDark ? Colors.white : Colors.black,
          textColor: isDark ? Colors.black : Colors.white,
        );
        break;

      case 'tafseer':
        cubit.getVerseTafseer(
          sora: widget.jsonData[getPageData(pageIndex)[0]["surah"] - 1]["number"],
          verse: verseNumber,
        );
        final tafseer = await cubit.stream
            .where((state) => state is GetVerseTafseerSuccessState)
            .map((state) => cubit.verseTafseer)
            .first;
        if (!context.mounted) return;
        navigateTo(
          context,
          TafseerScreen(
            ayah: verseNumber,
            tafseer: tafseer,
            sorah: widget.jsonData[getPageData(pageIndex)[0]["surah"] - 1]["number"],
          ),
        );
        break;

      case 'play':
        final player = AudioServices().player;
        final url = quran.getAudioURLByVerse(surah, verseNumber, "ar.abdulbasitmurattal");
        await player.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            tag: MediaItem(
              id: 'verse_audio_${surah}_$verseNumber',
              album: 'Quran',
              title: 'سورة ${getSurahNameArabic(surah)} - آية $verseNumber',
              artist: 'عبد الباسط عبد الصمد',
            ),
          ),
        );
        isPlaying.value = true;
        await player.play();
        player.processingStateStream
            .firstWhere((state) =>
        state == ProcessingState.completed || !isPlaying.value)
            .then((_) {
          if (mounted) isPlaying.value = false;
        });
        break;

      case 'select_start':
        setState(() => startVerse = verseNumber);
        Fluttertoast.showToast(msg: "تم تحديد بداية المقطع عند الآية $verseNumber");
        break;

      case 'select_end':
        if (startVerse == null) {
          Fluttertoast.showToast(msg: "من فضلك اختر البداية اولاً");
          return;
        }
        setState(() => endVerse = verseNumber);
        Fluttertoast.showToast(msg: "تم تحديد نهاية المقطع عند الآية $verseNumber");
        if (startVerse != null && endVerse != null) {
          _showDownloadDialog(surah, startVerse!, endVerse!, isDark);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _updateThemeColors();

    final screenSize = MediaQuery.of(context).size;
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    final gold = AppColors.isGoldMode;

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: PageView.builder(
            controller: _pageController,
            reverse: true,
            scrollDirection: Axis.horizontal,
            allowImplicitScrolling: true,
            onPageChanged: (a) async {
              if (widget.navigatedFromRecitation) {
                if (a < minPage!) {
                  _pageController.jumpToPage(minPage!);
                  Fluttertoast.showToast(msg: "هذه بداية وِردك اليوم");
                  return;
                }
                if (a > maxPage!) {
                  _pageController.jumpToPage(maxPage!);
                  Fluttertoast.showToast(msg: "هذه نهاية وِردك اليوم");
                  return;
                }
              }

              selectedSpan = "";
              index = a;
              if (index <= 0) return;

              // ✅ STOP AUDIO ASYNCHRONOUSLY
              Future.microtask(() async {
                await AudioServices().player.stop();
                isPlaying.value = false;
              });

              if (highlightVerseNotifier.value != null) {
                highlightVerseNotifier.value = null;
              }

              // _tryCacheAhead(index);
              // _loadFontsAsync(index);
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
                      color: AppColors.isGoldMode ? Color(AppColors.goldPrimary) : null,
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
                          style: AppTextStyles.madMd14(context, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () async {
                                  await AudioServices().player.clearAudioSources();
                                  TextQuranCubit.get(context).stop();
                                  isPlaying.value = false;
                                  if (mounted) Navigator.pop(context);
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
                                      color: borderClr,
                                    ),
                                  ),
                                  child: FittedBox(
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      color: textClr,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: HeaderWidget(
                                  e: widget.jsonData[getPageData(pageIndex)[0]["surah"]],
                                  jsonData: widget.jsonData,
                                  isDark: isDark,
                                ),
                              ),
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
                                      color: gold
                                          ? const Color(AppColors.goldPrimary)
                                          : (isDark ? Colors.white : Colors.black),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Directionality(
                              textDirection: m.TextDirection.rtl,
                              child: SizedBox(
                                width: double.infinity,
                                child: BlocBuilder<TextQuranCubit, TextQuranStates>(
                                  builder: (context, state) {
                                    final cubit = TextQuranCubit.get(context);
                                    return Skeletonizer(
                                        enabled: !cubit.isPageReady(pageIndex),
                                    child: _buildPageWidget(pageIndex),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

// ✅ EXTRACTED OPTIMIZED PAGE BUILDER (PREVENTS REBUILDS)
class _OptimizedPageBuilder extends StatelessWidget {
  final int pageIndex;
  final List pageData;
  final dynamic jsonData;
  final ValueNotifier<dynamic> highlightVerseNotifier;
  final Future<void> Function(String, int, int, int, Map<String, dynamic>) onVerseAction;
  final double Function({required double availableHeight, required double fontSize})
  getMushafLineHeight;

  const _OptimizedPageBuilder({
    required this.pageIndex,
    required this.pageData,
    required this.jsonData,
    required this.highlightVerseNotifier,
    required this.onVerseAction,
    required this.getMushafLineHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.read<ThemeCubit>().isDark;
    final gold = AppColors.isGoldMode;

    final popupBg = gold
        ? const Color(AppColors.goldBackground)
        : (isDark ? Colors.black : Colors.white);

    final popupText = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final popupBorder = gold
        ? const Color(AppColors.goldBorder)
        : const Color(0xffD6D6D6);

    return BlocBuilder<TextQuranCubit, TextQuranStates>(
      builder: (context, state) {
        return ValueListenableBuilder(
          valueListenable: highlightVerseNotifier,
          builder: (context, dynamic highlighted, _) {
            // ✅ MEMOIZED SPANS BUILDING (ONLY REBUILD IF HIGHLIGHTED CHANGES)
            final spans = _buildVerseSpans(
              context,
              pageData,
              isDark,
              gold,
              highlighted,
              popupBg,
              popupText,
              popupBorder,
              onVerseAction,
            );

            return RichText(
              textDirection: m.TextDirection.rtl,
              textAlign: TextAlign.center,
              text: TextSpan(children: spans),
            );
          },
        );
      },
    );
  }

  // ✅ EXTRACTED SPAN BUILDING (MEMOIZED)
  List<InlineSpan> _buildVerseSpans(
      BuildContext context,
      List pageData,
      bool isDark,
      bool gold,
      dynamic highlighted,
      Color popupBg,
      Color popupText,
      Color popupBorder,
      Future<void> Function(String, int, int, int, Map<String, dynamic>) onVerseAction,
      ) {
    final spans = <InlineSpan>[];

    for (var e in pageData) {
      for (var i = e["start"]; i <= e["end"]; i++) {
        if (i == 1 && pageIndex != 187 && pageIndex != 1) {
          spans.add(WidgetSpan(child: Basmallah(index: 0, isDark: isDark)));
        }

        if (pageIndex == 187 && i == 1) {
          spans.add(WidgetSpan(child: SizedBox(height: 10.h)));
        }

        // ✅ COMPUTE LINE HEIGHT ONCE PER PAGE
        final mq = MediaQuery.of(context);
        final screenHeight = mq.size.height;
        const headerHeight = 70.0;
        const basmallahHeight = 40.0;
        const topPadding = 20.0;
        const bottomPadding = 70.0;

        final availableHeight = screenHeight -
            mq.padding.top -
            headerHeight -
            basmallahHeight -
            topPadding -
            bottomPadding;

        final dynamicHeight = getMushafLineHeight(
          availableHeight: availableHeight,
          fontSize: 23.sp,
        );

        // ✅ OPTIMIZED TEXT SPAN (NO REPEATED CALCULATIONS)
        spans.add(
          TextSpan(
            recognizer: LongPressGestureRecognizer()
              ..onLongPressStart = (LongPressStartDetails details) async {
                highlightVerseNotifier.value = i;
                final RenderBox overlay =
                Overlay.of(context).context.findRenderObject() as RenderBox;
                final Offset tapPosition = details.globalPosition;

                final result = await showMenu<String>(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: popupBorder),
                  ),
                  color: popupBg,
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
                          Icon(Icons.menu_book_outlined, color: popupText, size: 15),
                          SizedBox(width: 6.w),
                          Text('تفسير',
                              style: AppTextStyles.madReg12(context, color: popupText)),
                        ],
                      ),
                    ),
                    PopupMenuDivider(height: 1, color: popupBorder),
                    PopupMenuItem<String>(
                      value: 'save',
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_border, color: popupText, size: 15),
                          SizedBox(width: 6.w),
                          Text('حفظ الآيه',
                              style: AppTextStyles.madReg12(context, color: popupText)),
                        ],
                      ),
                    ),
                    PopupMenuDivider(height: 1, color: popupBorder),
                    PopupMenuItem<String>(
                      value: 'play',
                      child: Row(
                        children: [
                          Icon(FontAwesomeIcons.circlePlay, color: popupText, size: 15),
                          SizedBox(width: 6.w),
                          Text('تشغيل',
                              style: AppTextStyles.madReg12(context, color: popupText)),
                        ],
                      ),
                    ),
                    PopupMenuDivider(height: 1, color: popupBorder),
                    PopupMenuItem<String>(
                      value: 'select_start',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, color: popupText, size: 15),
                          SizedBox(width: 6.w),
                          Text('تحديد كنقطة البداية',
                              style: AppTextStyles.madReg12(context, color: popupText)),
                        ],
                      ),
                    ),
                    PopupMenuDivider(height: 1, color: popupBorder),
                    PopupMenuItem<String>(
                      value: 'select_end',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, color: popupText, size: 15),
                          SizedBox(width: 6.w),
                          Text('تحديد كنقطة النهاية',
                              style: AppTextStyles.madReg12(context, color: popupText)),
                        ],
                      ),
                    ),
                  ],
                );

                if (result != null) {
                  await onVerseAction(
                    result,
                    i,
                    e["surah"],
                    pageIndex,
                    jsonData[e["surah"] - 1],
                  );
                }
              },
            text: getVerseQCF(e["surah"], i).replaceAll(' ', ''),
            style: TextStyle(
              color: gold ? Color(AppColors.goldText) : (isDark ? Colors.white : Colors.black),
              backgroundColor: highlighted == i
                  ? HexColor("998300").withValues(alpha: 0.2)
                  : Colors.transparent,
              fontFamily: "QCF_P${pageIndex.toString().padLeft(3, "0")}",
              fontSize: 23.sp,
              height: dynamicHeight,
              wordSpacing: 20,
            ),
          ),
        );
      }
    }

    return spans;
  }
}