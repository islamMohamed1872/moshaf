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
  final Map<int, Widget> _pageWidgetCache = {};
  String selectedSpan = "";
  int index = 0;
  int? startVerse;
  int? endVerse;
  int? minPage;
  int? maxPage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    index = widget.pageNumber;
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
  Future<Future<String?>> _showDownloadDialog(
      int surah,
      int start,
      int end,
      bool isDark,
      ) async
  {

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

    final cancelBtnText = gold
        ? const Color(AppColors.goldText)
        : Colors.black;

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
          style: AppTextStyles.madB14(
            context,
            color: titleColor,
          ),
        ),

        content: Text(
          "هل تريد تحميل الآيات من $start إلى $end من سورة ${quran.getSurahNameArabic(surah)}؟",
          textAlign: TextAlign.center,
          style: AppTextStyles.madReg12(
            context,
            color: textColor,
          ),
        ),

        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [

          // Cancel Button
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: cancelBtnBg,
              foregroundColor: cancelBtnText,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "إلغاء",
              style: AppTextStyles.madReg14(context, color: cancelBtnText),
            ),
          ),

          // Download Button
          TextButton.icon(
            icon: Icon(
              Icons.download,
              size: 18,
              color: gold ? Colors.white : Colors.white,
            ),
            label: Text(
              "تحميل",
              style: AppTextStyles.madReg14(context, color: Colors.white),
            ),
            style: TextButton.styleFrom(
              backgroundColor: downloadBtnBg,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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

      // -------------------------------------------------------------
      // 🔹 Step 1: Download Each Verse
      // -------------------------------------------------------------
      for (int i = start; i <= end; i++) {
        final url = quran.getAudioURLByVerse(surah, i, "ar.abdulbasitmurattal");
        final savePath = "${tempDir.path}/verse_$i.mp3";

        await dio.download(url, savePath);
        files.add(savePath);

        debugPrint("✅ Downloaded verse $i");
      }

      // -------------------------------------------------------------
      // 🔹 Step 2: Prepare output file name
      // -------------------------------------------------------------
      final surahNameArabic = quran.getSurahNameArabic(surah);
      final sanitizedSurahName = surahNameArabic.replaceAll(" ", "_");

      final combinedFileName =
          "سورة_${sanitizedSurahName}_من_${start}_الى_${end}.mp3";

      // -------------------------------------------------------------
      // 🔹 Step 3: Resolve a safe Downloads directory
      // -------------------------------------------------------------
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

      // -------------------------------------------------------------
      // 🔹 Step 4: Merge all the audio files
      // -------------------------------------------------------------
      await _combineAudioFiles(files, combinedPath);

      // -------------------------------------------------------------
      // 🔹 Step 5: Remove temp files
      // -------------------------------------------------------------
      for (final path in files) {
        try {
          await File(path).delete();
        } catch (_) {}
      }

      // -------------------------------------------------------------
      // 🔹 Step 6: Success Toast + Share Dialog
      // -------------------------------------------------------------
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
        // Write full file including ID3 header
        output.add(bytes);
        isFirst = false;
      } else {
        // Skip ID3 header in subsequent MP3 files
        int skip = _getID3HeaderSize(bytes);
        output.add(bytes.sublist(skip));
      }
    }

    await output.close();
  }

  int _getID3HeaderSize(List<int> bytes) {
    if (bytes.length < 10) return 0;

    // Check for "ID3" signature: 0x49 0x44 0x33
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      // Size is stored in bytes 6–9 (syncsafe integer)
      int size = (bytes[6] << 21) |
      (bytes[7] << 14) |
      (bytes[8] << 7) |
      bytes[9];

      // Header is 10 bytes + tag size
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
        title: Text(
          "تم التحميل بنجاح",
          textAlign: TextAlign.center,
          style: AppTextStyles.madB14(context, color: textColor),
        ),
        content: Text(
          "تم حفظ الملف:\n"
              "سورة $surahName من $start إلى $end\n\n"
              "هل ترغب بمشاركته على واتساب؟",
          textAlign: TextAlign.center,
          style: AppTextStyles.madReg12(context,
              color: isGold ? const Color(AppColors.goldText) : (isDark ? Colors.white70 : Colors.black87)),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          /// ❌ Close button
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

          /// 📤 Share to WhatsApp
          TextButton.icon(
            icon: const Icon(Icons.share, size: 18, color: Colors.white),
            label: Text(
              "واتساب",
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
  void _tryCacheAhead(int currentPage,bool isDark) {
    // Cache current if missing
    if (!_pageWidgetCache.containsKey(currentPage)) {
      _pageWidgetCache[currentPage] = _buildPageWidget(currentPage,isDark);
    }
    // Cache next 5 ahead if missing
    for (
      int i = currentPage + 1;
      i <= currentPage + 5 && i <= totalPagesCount;
      i++
    ) {
      if (!_pageWidgetCache.containsKey(i)) {
        _pageWidgetCache[i] = _buildPageWidget(i,isDark);
      }
    }
  }

  Widget _buildPageWidget(int pageIndex,isDark) {
    if (pageIndex <= 0) return SizedBox();
    if (_pageWidgetCache.containsKey(pageIndex)) {
      return _pageWidgetCache[pageIndex]!;
    }
    final pageData = getPageData(pageIndex);

    final widget2 = BlocBuilder<TextQuranCubit, TextQuranStates>(
      builder: (context, state) {
        final cubit = TextQuranCubit.get(context);
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
            final spans = <InlineSpan>[];

            for (var e in pageData) {
              for (var i = e["start"]; i <= e["end"]; i++) {
                if (i == 1) {
                  // spans.add(WidgetSpan(
                  //   child: HeaderWidget(e: e, jsonData: widget.jsonData),
                  // ));
                  // if(getPageData(
                  //   pageIndex,
                  // ).length>1){
                  //   spans.add(WidgetSpan(child: HeaderWidget(
                  //     e:
                  //     widget.jsonData[getPageData(
                  //       pageIndex,
                  //     )[getPageData(
                  //       pageIndex,
                  //     ).length-1]["surah"]],
                  //     jsonData: widget.jsonData,
                  //     isDark: isDark,
                  //   ),));
                  // }
                  if (pageIndex != 187 && pageIndex != 1) {
                    spans.add(WidgetSpan(child: Basmallah(index: 0,isDark: isDark,)));
                  }
                  print(getPageData(
                    pageIndex,
                  ));

                  if (pageIndex == 187) {
                    spans.add(WidgetSpan(child: SizedBox(height: 10.h)));
                  }
                }

                final screenHeight = MediaQuery.of(context).size.height;
// Dynamic line height (makes full page fit)
                final dynamicHeight = screenHeight * 0.0021.h;
                spans.add(
                  TextSpan(
                    recognizer:
                    LongPressGestureRecognizer()
                      ..onLongPressStart = (LongPressStartDetails details) async {
                        highlightVerseNotifier.value = i;

                        // Get overlay for positioning
                        final RenderBox overlay =
                        Overlay.of(context).context.findRenderObject() as RenderBox;
                        final Offset tapPosition = details.globalPosition;

                        // 🔹 Show popup menu
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

                        // ==========================
                        // 🔹 Handle Actions
                        // ==========================

                        if (result == 'save') {
                          cubit.saveLastRead(
                            page: pageIndex,
                            verse: i,
                            sora: widget.jsonData[
                            getPageData(pageIndex)[0]["surah"] - 1]["number"],
                          );

                          Fluttertoast.showToast(
                            msg: " تم حفظ تقدمك بنجاح",
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            textColor: isDark ? Colors.black : Colors.white,
                          );
                        }

                        else if (result == 'tafseer') {
                          cubit.getVerseTafseer(
                            sora: widget.jsonData[
                            getPageData(pageIndex)[0]["surah"] - 1]["number"],
                            verse: i,
                          );

                          final tafseer = await cubit.stream
                              .where((state) => state is GetVerseTafseerSuccessState)
                              .map((state) => cubit.verseTafseer)
                              .first;

                          if (!context.mounted) return;

                          navigateTo(
                            context,
                            TafseerScreen(
                              ayah: i,
                              tafseer: tafseer,
                              sorah: widget.jsonData[
                              getPageData(pageIndex)[0]["surah"] - 1]["number"],
                            ),
                          );
                        }

                        else if (result == 'play') {
                          final player = AudioServices().player;
                          final url = quran.getAudioURLByVerse(
                              e["surah"], i, "ar.abdulbasitmurattal");

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

                          player.processingStateStream.firstWhere((state) =>
                          state == ProcessingState.completed || !isPlaying.value).then((_) {
                            if (mounted) isPlaying.value = false;
                          });
                        }

                        else if (result == 'select_start') {
                          setState(() => startVerse = i);
                          Fluttertoast.showToast(msg: "تم تحديد بداية المقطع عند الآية $i");
                        }

                        else if (result == 'select_end') {
                          if (startVerse == null) {
                            Fluttertoast.showToast(msg: "من فضلك اختر البداية اولاً");
                            return;
                          }
                          setState(() => endVerse = i);
                          Fluttertoast.showToast(msg: "تم تحديد نهاية المقطع عند الآية $i");

                          if (startVerse != null && endVerse != null) {
                            _showDownloadDialog(e["surah"], startVerse!, endVerse!, isDark);
                          }
                        }
                      },
                      text: getVerseQCF(e["surah"], i).replaceAll(' ', ''),
                    style: TextStyle(
                      color:gold? Color(AppColors.goldText): isDark? Colors.white:Colors.black,
                      backgroundColor:
                          highlighted == i
                              ? HexColor("998300").withValues(alpha: 0.2)
                              : Colors.transparent,
                      fontFamily:
                          "QCF_P${pageIndex.toString().padLeft(3, "0")}",
                        fontSize: 23.sp,
                      height: dynamicHeight, //1.8.h
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
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    final gold = AppColors.isGoldMode;

    // Colors
    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final backIconClr = gold
        ? const Color(AppColors.goldAccent)
        : (isDark ? Colors.white : Colors.black);

    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.ltr, // Force LTR scrolling logic
          child: PageView.builder(
            controller: _pageController,
            reverse: true,
            scrollDirection: Axis.horizontal,
            allowImplicitScrolling: true,
            onPageChanged: (a) async{
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
              await AudioServices().player.stop();
              isPlaying.value = false;
              if(highlightVerseNotifier.value!=null) highlightVerseNotifier.value=null;
              _tryCacheAhead(index,isDark);
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
                      color: AppColors.isGoldMode? Color(AppColors.goldPrimary):null,
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
                            style: AppTextStyles.madMd14(context,color:Colors.white),
                          ),
                        ],
                      )
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 🔹 BACK BUTTON
                              InkWell(
                                onTap: () async {
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
                                      color: gold
                                          ? const Color(AppColors.goldBorder)
                                          : Color(isDark
                                          ? AppColors.containerDarkBorders
                                          : AppColors.containerLightBorders),
                                    ),
                                  ),
                                  child: FittedBox(
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      color: gold
                                          ? const Color(AppColors.goldText)
                                          : (isDark ? Colors.white : Colors.black),
                                    ),
                                  ),
                                ),
                              ),

                              // 🔹 HEADER TITLE
                              Expanded(
                                child: HeaderWidget(
                                  e: widget.jsonData[getPageData(pageIndex)[0]["surah"]],
                                  jsonData: widget.jsonData,
                                  isDark: isDark,
                                ),
                              ),

                              // 🔹 PLAY / PAUSE BUTTON
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
                        if (pageIndex == 1 || pageIndex == 2)
                          SliverToBoxAdapter(
                            child: SizedBox(height: screenSize.height * .001),
                          ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Directionality(
                              textDirection: m.TextDirection.rtl,
                              child: SizedBox(
                                width: double.infinity,
                                child: BlocBuilder<TextQuranCubit, TextQuranStates>(
                                  builder: (context, state) => Transform.scale(
                                    scale: 0.95,
                                    alignment: Alignment.center,
                                    child: Skeletonizer(
                                      enabled: !TextQuranCubit.get(context).isFontLoaded(pageIndex),
                                      child: _buildPageWidget(pageIndex, isDark),
                                    ),
                                  ),
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

