import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../components/cache_helper.dart';
import '../../../components/const.dart';
import '../../../controllers/recitation/recitation_cubit.dart';
import '../../../controllers/text_quran/quran_font_manager.dart';
import '../../../controllers/text_quran/text_quran_states.dart';
import '../../../controllers/theme/theme_cubit.dart';
import 'basmallah.dart';
import 'coach_content.dart';
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
    required this.navigatedFromRecitation,
  }) : super(key: key);

  @override
  State<QuranViewPage> createState() => _QuranViewPageState();
}

class _QuranViewPageState extends State<QuranViewPage>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  late ValueNotifier<dynamic> highlightVerseNotifier;
  ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<int> fontsVersion = ValueNotifier<int>(0);

  int index = 0;
  int? startVerse;
  int? endVerse;
  int? minPage;
  int? maxPage;
  int? _currentVerseIndex;

  TutorialCoachMark? _coach;
  bool _tutorialStarted = false;

  final GlobalKey _backKey = GlobalKey();
  final GlobalKey _playKey = GlobalKey();
  final GlobalKey _ayahAreaKey = GlobalKey();
  final GlobalKey _pageNumberKey = GlobalKey();


  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    index = widget.pageNumber;

    _pageController = PageController(initialPage: index);

    // ✅ make sure initial page font is requested
    QuranFontManager.instance.requestPriority(page: widget.pageNumber);

    if (widget.navigatedFromRecitation) {
      final recitationCubit = RecitationCubit.get(context);
      final range = recitationCubit.getDailyReadingRange();
      minPage = range['startPage'];
      maxPage = range['endPage'];
    }

    highlightVerseNotifier = ValueNotifier<int?>(
      int.tryParse(widget.highlightVerse ?? ''),
    );

    final player = AudioServices().player;
    player.playerStateStream.listen((state) {
      if (!mounted) return;
      isPlaying.value = state.playing;
    });

    if (widget.shouldHighlightText) {
      _startHighlightAnimation();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _tryStartTutorial();
    });

  }

  Future<void> _tryStartTutorial() async {
    if (_tutorialStarted) return;
    _tutorialStarted = true;

    final shown = await CacheHelper.getData(key: "quran_view_tutorial_shown") ?? false;
    if (shown == true) return;

    // wait for first build + fonts settle a bit
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    _showTutorial();
  }

  void _showTutorial() {
    final isDark = context.read<ThemeCubit>().isDark;
    final gold = AppColors.isGoldMode;

    final titleClr = gold ? const Color(AppColors.goldAccent) : Colors.white;
    final descClr = Colors.white.withOpacity(0.9);

    final targets = <TargetFocus>[
      TargetFocus(
        identify: "back",
        keyTarget: _backKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: CoachContent(
              title: "رجوع",
              description: "اضغط هنا للعودة إلى قائمة السور.",
              titleColor: titleClr,
              descColor: descClr,
            ),
          ),
        ],
      ),

      TargetFocus(
        identify: "play",
        keyTarget: _playKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: CoachContent(
              title: "تشغيل التلاوة 🎧",
              description: "تشغيل/إيقاف تلاوة آيات الصفحة الحالية بشكل متتابع.",
              titleColor: titleClr,
              descColor: descClr,
            ),
          ),
        ],
      ),

      TargetFocus(
        identify: "ayah_area",
        keyTarget: _ayahAreaKey,
        shape: ShapeLightFocus.RRect,
        radius: 14,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: CoachContent(
              title: "تفاعل مع الآيات ✨",
              description:
              "اضغط مطولًا على أي آية لعرض الخيارات:\n"
                  "• تفسير\n"
                  "• حفظ\n"
                  "• تشغيل\n"
                  "• تحديد بداية/نهاية لتحميل المقطع\n"
                  "• مشاركة كصورة",
              titleColor: titleClr,
              descColor: descClr,
            ),
          ),
        ],
      ),

      TargetFocus(
        identify: "page_number",
        keyTarget: _pageNumberKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: CoachContent(
              title: "رقم الصفحة",
              description: "هنا يظهر رقم الصفحة داخل المصحف.",
              titleColor: titleClr,
              descColor: descClr,
            ),
          ),
        ],
      ),
    ];

    _coach?.finish();

    _coach = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.85),
      textSkip: "تخطي",
      paddingFocus: 10,
      opacityShadow: 0.85,
      onFinish: () async {
        await CacheHelper.saveData(key: "quran_view_tutorial_shown", value: true);
        _coach = null;
      },
      onSkip: () {
        CacheHelper.saveData(key: "quran_view_tutorial_shown", value: true);
        _coach = null;
        return true;
      },
    );

    _coach!.show(context: context);
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
      final int? verseAsInt =
      int.tryParse(widget.highlightVerse?.toString() ?? '');
      highlightVerseNotifier.value =
      highlightVerseNotifier.value == null ? verseAsInt : null;

      if (timer.tick >= 7) {
        highlightVerseNotifier.value = null;
        timer.cancel();
      }
    });
  }

  Future<String?> _showDownloadDialog(
      int surah,
      int start,
      int end,
      bool isDark,
      ) async
  {
    final gold = AppColors.isGoldMode;

    final bgColor = gold
        ? const Color(AppColors.goldBackground)
        : (isDark ? const Color(AppColors.scaffoldBg) : Colors.white);

    final titleColor = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final textColor = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white70 : Colors.black87);

    final cancelBtnBg =
    gold ? const Color(AppColors.goldBorder).withOpacity(.2) : Colors.grey.shade200;

    final cancelBtnText = gold ? const Color(AppColors.goldText) : Colors.black;

    final downloadBtnBg =
    gold ? const Color(AppColors.goldPrimary) : const Color(AppColors.mainGreen);

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
            child: Text(
              "إلغاء",
              style: AppTextStyles.madReg14(context, color: cancelBtnText),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.download, size: 18, color: Colors.white),
            label: Text(
              "تحميل",
              style: AppTextStyles.madReg14(context, color: Colors.white),
            ),
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

      // cleanup temp verses
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
    } catch (e) {
      Fluttertoast.showToast(msg: "❌ حدث خطأ أثناء التحميل");
    }
  }

  /// ✅ combine MP3 files safely by removing ID3 headers except first file
  Future<void> _combineAudioFiles(List<String> inputPaths, String outputPath) async {
    final out = File(outputPath).openWrite();
    bool first = true;

    for (final p in inputPaths) {
      final bytes = await File(p).readAsBytes();
      if (bytes.isEmpty) continue;

      if (first) {
        out.add(bytes);
        first = false;
      } else {
        final skip = _getID3HeaderSize(bytes);
        out.add(bytes.sublist(skip));
      }
    }

    await out.close();
  }

  int _getID3HeaderSize(List<int> bytes) {
    if (bytes.length < 10) return 0;

    // ID3 signature
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      // syncsafe int size
      final size =
      (bytes[6] << 21) | (bytes[7] << 14) | (bytes[8] << 7) | bytes[9];
      return size + 10;
    }
    return 0;
  }

  void _showShareDialog(String filePath, String surahName, int start, int end) {
    final isDark = context.read<ThemeCubit>().isDark;
    final isGold = AppColors.isGoldMode;

    final bgColor = isGold
        ? const Color(AppColors.goldBackground)
        : (isDark ? const Color(AppColors.scaffoldBg) : Colors.white);

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
        title: Text(
          "تم التحميل بنجاح",
          textAlign: TextAlign.center,
          style: AppTextStyles.madB14(context, color: textColor),
        ),
        content: Text(
          "تم حفظ الملف:\nسورة $surahName من $start إلى $end\n\nهل ترغب بمشاركته؟",
          textAlign: TextAlign.center,
          style: AppTextStyles.madReg12(
            context,
            color: isGold ? const Color(AppColors.goldText) : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: isGold ? const Color(0xFFE6C87A) : Colors.grey.shade200,
              foregroundColor: textColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "إغلاق",
              style: AppTextStyles.madReg14(context, color: textColor),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.share, size: 18, color: Colors.white),
            label: Text(
              "مشاركة",
              style: AppTextStyles.madReg14(context, color: Colors.white),
            ),
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


  double getMushafLineHeight({
    required double availableHeight,
    required double fontSize,
  })
  {
    const mushafLines = 15;
    return availableHeight / (mushafLines * fontSize);
  }

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

  Future<void> _handleVerseAction(
      String action,
      int verseNumber,
      int surah,
      int pageIndex,
      Map<String, dynamic> surahData,
      ) async
  {
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
        final url = quran.getAudioURLByVerse(
          surah,
          verseNumber,
          "ar.abdulbasitmurattal",
        );

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
          // ✅ ensure correct ordering
          final s = startVerse!;
          final e = endVerse!;
          final start = s <= e ? s : e;
          final end = s <= e ? e : s;

          // ✅ show dialog and download
          await _showDownloadDialog(surah, start, end, isDark);
        }
        break;
      case 'share_image':
        await shareAyahAsImage(
          surah: surah,
          verse: verseNumber,
          pageIndex: pageIndex,
        );
        break;
    }
  }

  Future<Uint8List> captureWidgetAsPng(
      BuildContext context,
      Widget widget, {
        double pixelRatio = 3,
        Size size = const Size(1000, 1000),
      }) async {
    final repaintKey = GlobalKey();
    Uint8List? resultBytes;

    final captureWidget = Material(
      color: Colors.transparent,
      child: RepaintBoundary(
        key: repaintKey,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: widget,
        ),
      ),
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) {
      throw Exception("Overlay is null");
    }

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000,
        top: -10000,
        child: captureWidget,
      ),
    );

    overlay.insert(entry);

    try {
      // ✅ Force build & paint
      await Future.delayed(const Duration(milliseconds: 30));
      await WidgetsBinding.instance.endOfFrame;

      for (int attempt = 0; attempt < 40; attempt++) {
        final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

        if (boundary == null || boundary.size.isEmpty) {
          await WidgetsBinding.instance.endOfFrame;
          continue;
        }

        try {
          final image = await boundary.toImage(pixelRatio: pixelRatio);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

          if (byteData != null) {
            resultBytes = byteData.buffer.asUint8List();
            break;
          }
        } catch (_) {
          await WidgetsBinding.instance.endOfFrame;
        }
      }
    } finally {
      entry.remove();
    }

    if (resultBytes == null) {
      throw Exception("Failed to capture widget as PNG (no bytes produced)");
    }

    return resultBytes;
  }



  Future<void> shareAyahAsImage({
    required int surah,
    required int verse,
    required int pageIndex,
  }) async {
    try {
      _coach?.finish();
      _coach = null;
      Fluttertoast.showToast(msg: "⏳ جاري إنشاء الصورة...");

      // ✅ Ensure font is loaded
      await QuranFontManager.instance.ensureFontLoaded(pageIndex);
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 500));

      final isDark = context.read<ThemeCubit>().isDark;
      final gold = AppColors.isGoldMode;

      final bgColor = gold
          ? const Color(AppColors.goldBackground)
          : (isDark ? const Color(AppColors.scaffoldBg) : Colors.white);

      final textColor = isDark ? Colors.white : Colors.black;

      // ✅ Build simple widget for capture
      final widgetToShare = Scaffold(
        body: Container(
          width: 1000,
          height: 1000,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: bgColor,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                right: 0,
                left: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        getVerseQCF(surah, verse).replaceAll(' ', ''),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "QCF_P${pageIndex.toString().padLeft(3, "0")}",
                          fontSize: 70,
                          height: 1.7,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "سورة ${quran.getSurahNameArabic(surah)} • آية $verse",
                      style: TextStyle(
                        fontSize: 26,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset("assets/images/logo.png",width: 70,height: 70,)),
              )
            ],
          ),
        ),
      );

      // ✅ Capture with timeout
      final bytes = await captureWidgetAsPng(
        context,
        widgetToShare,
        size: const Size(1000, 1000),
        pixelRatio: 3,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException("Widget capture took too long");
        },
      );

      final dir = await getTemporaryDirectory();
      final fileName = "ayah_${surah}_${verse}_${DateTime.now().millisecondsSinceEpoch}.png";
      final file = File("${dir.path}/$fileName");

      await file.writeAsBytes(bytes);

      if (!file.existsSync()) {
        throw Exception("File was not saved properly");
      }

      Fluttertoast.showToast(msg: "✅ تم إنشاء الصورة بنجاح");

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "﴿ ${quran.getSurahNameArabic(surah)}:$verse ﴾",
      );

      // ✅ Cleanup after share
      try {
        await Future.delayed(const Duration(seconds: 2));
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (_) {}

    } on TimeoutException catch (e) {
      print("❌ Timeout: $e");
      Fluttertoast.showToast(
        msg: "⚠️ انتظر قليلاً ثم حاول مجددا",
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e, st) {
      print("❌ Share ayah image error: $e");
      debugPrint("STACKTRACE:\n$st");
      Fluttertoast.showToast(
        msg: "⚠️ حدث خطأ في مشاركة الآية",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }






  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    final gold = AppColors.isGoldMode;

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

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
              _coach?.finish();
              _coach = null;
              // ✅ page 0 is cover
              if (a <= 0) return;

              QuranFontManager.instance.requestPriority(page: a);

              // preload neighbors cache
              QuranFontManager.instance.requestBackground(page: a + 1);
              QuranFontManager.instance.requestBackground(page: a - 1);

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

              setState(() {
                index = a;
              });

              Future.microtask(() async {
                await AudioServices().player.stop();
                isPlaying.value = false;
              });

              if (highlightVerseNotifier.value != null) {
                highlightVerseNotifier.value = null;
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

              // ✅ VERY IMPORTANT: request font for this page early
              QuranFontManager.instance.requestPriority(page: pageIndex);

              return Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: Image.asset(
                      "assets/images/quran_bg.png",
                      color: gold ? Color(AppColors.goldPrimary) : null,
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 0,
                    left: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          key: (pageIndex == index) ? _pageNumberKey : null,
                          child: Text(
                            TextQuranCubit.get(context)
                                .convertToArabic(pageIndex.toString()),
                            style: AppTextStyles.madMd14(context, color: Colors.white),
                          ),
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
                                  key: (pageIndex == index) ? _backKey : null,
                                  width: 30.w,
                                  height: 30.w,
                                  padding: EdgeInsetsDirectional.only(
                                    start: 7.w,
                                    top: 5,
                                    bottom: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: borderClr),
                                  ),
                                  child: FittedBox(
                                    child: Icon(Icons.arrow_back_ios, color: textClr),
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
                                    key: (pageIndex == index) ? _playKey : null,
                                    onTap: () async {
                                      final pageData = getPageData(index);
                                      await playSurahVersesSequentially(pageData);
                                    },
                                    child: Icon(
                                      playing
                                          ? FontAwesomeIcons.pause
                                          : FontAwesomeIcons.play,
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
                              child: Container(
                                key: (pageIndex == index) ? _ayahAreaKey : null,
                                width: double.infinity,
                                child: BlocBuilder<TextQuranCubit, TextQuranStates>(
                                  builder: (context, state) {
                                   return ValueListenableBuilder<int>(
                                      valueListenable: QuranFontManager.instance.fontsVersion,
                                      builder: (context, _, __) {
                                        return Skeletonizer(
                                          enabled: !QuranFontManager.instance.isLoaded(pageIndex),
                                          child: _buildPageWidget(pageIndex),
                                        );
                                      },
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

class _OptimizedPageBuilder extends StatelessWidget {
  final int pageIndex;
  final List pageData;
  final dynamic jsonData;
  final ValueNotifier<dynamic> highlightVerseNotifier;
  final Future<void> Function(String, int, int, int, Map<String, dynamic>)
  onVerseAction;
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

    return ValueListenableBuilder(
      valueListenable: highlightVerseNotifier,
      builder: (context, dynamic highlighted, _) {
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
          getMushafLineHeight,
        );

        return RichText(
          textDirection: m.TextDirection.rtl,
          textAlign: TextAlign.center,
          text: TextSpan(children: spans),
        );
      },
    );
  }

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
      double Function({required double availableHeight, required double fontSize})
      getMushafLineHeight,
      ) {
    final spans = <InlineSpan>[];

    // ✅ compute line height once per page
    final mq = MediaQuery.of(context);
    final screenHeight = mq.size.height;
    bool firstVerseHandled = false;
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

    for (var e in pageData) {
      for (var i = e["start"]; i <= e["end"]; i++) {
        if (i == 1 && pageIndex != 187 && pageIndex != 1) {
          spans.add(WidgetSpan(child: Basmallah(index: 0, isDark: isDark)));
        }

        if (pageIndex == 187 && i == 1) {
          spans.add(WidgetSpan(child: SizedBox(height: 10.h)));
        }

        // In _buildVerseSpans method, replace the onLongPressStart section:

        spans.add(
          TextSpan(
            recognizer: LongPressGestureRecognizer()
              ..onLongPressStart = (LongPressStartDetails details) async {
                highlightVerseNotifier.value = i;
                if (!context.mounted) return;

                final RenderBox overlay =
                Overlay.of(context).context.findRenderObject() as RenderBox;
                final Offset tapPosition = details.globalPosition;

                // ✅ Initialize result to null instead of late
                String? result;

                try {
                  result = await showMenu<String>(
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
                      PopupMenuDivider(height: 1, color: popupBorder),
                      PopupMenuItem<String>(
                        value: 'share_image',
                        child: Row(
                          children: [
                            Icon(Icons.image_outlined, color: popupText, size: 15),
                            SizedBox(width: 6.w),
                            Text(
                              'مشاركة كصورة',
                              style: AppTextStyles.madReg12(context, color: popupText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } catch (e, st) {
                  debugPrint("❌ showMenu failed: $e");
                  debugPrint("STACKTRACE:\n$st");
                  result = null;
                }

                // ✅ Now result is always initialized
                if (result != null && context.mounted) {
                  await onVerseAction(
                    result,
                    i,
                    e["surah"],
                    pageIndex,
                    jsonData[e["surah"] - 1],
                  );
                }
              },
            text: () {
              final raw = getVerseQCF(e["surah"], i).replaceAll(' ', '');

              if (!firstVerseHandled) {
                firstVerseHandled = true;
                return _addSpaceAfterFirstWord(raw);
              }

              return raw;
            }(),
            style: TextStyle(
              color: gold ? Color(AppColors.goldText) : (isDark ? Colors.white : Colors.black),
              backgroundColor: highlighted == i
                  ? HexColor("998300").withValues(alpha: 0.2)
                  : Colors.transparent,
              fontFamily: "QCF_P${pageIndex.toString().padLeft(3, "0")}",
              fontSize: 23.sp,
              height: dynamicHeight,
              // wordSpacing: 20,
            ),
          ),
        );
      }
    }

    return spans;
  }
  String _addSpaceAfterFirstWord(String text) {
    final match = RegExp(r'^(.+?)([^\u0600-\u06FF]*)').firstMatch(text);

    if (match == null) return text;

    final firstWord = match.group(1)!;
    final rest = text.substring(firstWord.length);

    return '$firstWord\u200A$rest';
  }
}
