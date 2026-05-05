import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';
import 'package:moshaf/controllers/text_quran/text_quran_cubit.dart';
import 'package:moshaf/controllers/text_quran/text_quran_states.dart';
import 'package:moshaf/views/quran/tafseer_screen.dart';
import 'package:moshaf/views/widgets/header.dart';
import 'package:quran/quran.dart' as quran;

class TafseerSearchScreen extends StatefulWidget {
  const TafseerSearchScreen({super.key});

  @override
  State<TafseerSearchScreen> createState() => _TafseerSearchScreenState();
}

class _TafseerSearchScreenState extends State<TafseerSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _query = '';
  List<_AyahSuggestion> _suggestions = [];

  // ── Tashkeel + Quranic marks stripper ────────────────────
  // Covers all marks the quran dart package uses:
  //   U+064B–U+065F  standard tashkeel (fatha, damma, kasra, shadda, sukun…)
  //   U+0670         superscript alef ٰ  (in الله، الرحمن…)
  //   U+06D6–U+06ED  Quranic annotation signs (pause/sajda marks)
  //   U+0610–U+061A  extended Arabic marks
  String _strip(String text) => text
      .replaceAll(RegExp('[\u064B-\u065F]'), '')
      .replaceAll(RegExp('[\u06D6-\u06ED]'), '')
      .replaceAll(RegExp('[\u0610-\u061A]'), '')
      .trim();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    // Auto-open keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Search logic ──────────────────────────────────────────

  void _onChanged() {
    final q = _controller.text.trim();
    setState(() {
      _query = q;
      _suggestions = q.isEmpty ? [] : _search(q);
    });
  }

  List<_AyahSuggestion> _search(String raw) {
    // Strip tashkeel AND normalize alef variants so ا/أ/إ/آ all match
    final query = _normalize(_strip(raw).toLowerCase());
    if (query.isEmpty) return [];

    final results = <_AyahSuggestion>[];

    for (int s = 1; s <= 114; s++) {
      // Strip + normalize the surah name once per surah
      final surahName = _normalize(_strip(quran.getSurahNameArabic(s)).toLowerCase());
      final count = quran.getVerseCount(s);

      for (int v = 1; v <= count; v++) {
        // Strip + normalize each verse
        final text = _normalize(_strip(quran.getVerse(s, v)).toLowerCase());

        if (text.contains(query) || surahName.contains(query)) {
          results.add(_AyahSuggestion(surah: s, verse: v));
          if (results.length >= 30) return results;
        }
      }
    }

    return results;
  }

  /// Normalizes alef variants so أ / إ / آ / ٱ / ٱ (U+0671) all match ا
  String _normalize(String text) => text
      .replaceAll(RegExp('[أإآٱ\u0671]'), 'ا')
      .replaceAll('\u0670', 'ا')  // superscript alef (يَٰ → يا)
      .replaceAll(RegExp('[ىئ]'), 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و');

  // ── Navigate to tafseer ───────────────────────────────────

  Future<void> _openTafseer(BuildContext context, int surah, int verse) async {
    final cubit = TextQuranCubit.get(context);
    cubit.getVerseTafseer(sora: surah, verse: verse);

    final tafseer = await cubit.stream
        .where((s) => s is GetVerseTafseerSuccessState)
        .map((_) => cubit.verseTafseer)
        .first;

    if (!context.mounted) return;

    navigateTo(
      context,
      TafseerScreen(
        ayah: verse,
        tafseer: tafseer,
        sorah: surah,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = context.select((ThemeCubit c) => c.isDark);
    final gold     = AppColors.isGoldMode;

    final bgClr = gold
        ? const Color(AppColors.goldBackground)
        : (isDark ? const Color(AppColors.scaffoldBg) : Colors.white);

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final accentClr = gold
        ? const Color(AppColors.goldPrimary)
        : Color(AppColors.mainGreen);

    final hintClr = textClr.withValues(alpha: 0.35);
    final subtitleClr = textClr.withValues(alpha: 0.55);

    return Scaffold(
      backgroundColor: bgClr,
      body: SafeArea(
        child: Column(
          children: [

            // ── Header ────────────────────────────────────────
            Header(
              title: "التفسير",
              onTap: () => Navigator.pop(context),
              isDark: isDark,
              iconColor: gold ? const Color(AppColors.goldAccent) : null,
            ),

            SizedBox(height: 16.h),

            // ── Search field ──────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderClr),
                  color: accentClr.withValues(alpha: 0.04),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: accentClr, size: 20.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.madReg14(context, color: textClr),
                        decoration: InputDecoration(
                          hintText: "ابحث بكلمة من الآية أو اسم السورة...",
                          hintStyle: AppTextStyles.madReg14(
                              context, color: hintClr),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          setState(() {
                            _query = '';
                            _suggestions = [];
                          });
                        },
                        child: Icon(Icons.close_rounded,
                            color: accentClr, size: 18.sp),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10.h),

            // ── Divider ───────────────────────────────────────
            Container(height: 1, color: borderClr),

            SizedBox(height: 4.h),

            // ── Body ──────────────────────────────────────────
            Expanded(
              child: _query.isEmpty
                  ? _buildEmptyPrompt(context, accentClr, subtitleClr)
                  : _suggestions.isEmpty
                  ? _buildNoResults(context, textClr, accentClr)
                  : _buildSuggestions(
                context,
                borderClr,
                textClr,
                accentClr,
                subtitleClr,
                isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state (no query yet) ────────────────────────────

  Widget _buildEmptyPrompt(
      BuildContext context, Color accentClr, Color subtitleClr) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined,
              size: 56.sp, color: accentClr.withValues(alpha: 0.35)),
          SizedBox(height: 14.h),
          Text(
            "اكتب كلمة أو جزءاً من آية\nأو اسم سورة للبحث عن تفسيرها",
            textAlign: TextAlign.center,
            style: AppTextStyles.madReg14(context, color: subtitleClr),
          ),
        ],
      ),
    );
  }

  // ── No results ────────────────────────────────────────────

  Widget _buildNoResults(
      BuildContext context, Color textClr, Color accentClr) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48.sp, color: accentClr.withValues(alpha: 0.35)),
          SizedBox(height: 12.h),
          Text(
            "لا توجد نتائج لـ \"$_query\"",
            style: AppTextStyles.madReg14(context, color: textClr),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Suggestions list ──────────────────────────────────────

  Widget _buildSuggestions(
      BuildContext context,
      Color borderClr,
      Color textClr,
      Color accentClr,
      Color subtitleClr,
      bool isDark,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          child: Text(
            "${_suggestions.length} نتيجة${_suggestions.length == 30 ? ' (أول 30)' : ''}",
            style: AppTextStyles.madReg12(context, color: accentClr),
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final sug = _suggestions[index];
              return _SuggestionTile(
                suggestion: sug,
                query: _query,
                borderClr: borderClr,
                textClr: textClr,
                accentClr: accentClr,
                subtitleClr: subtitleClr,
                onTap: () => _openTafseer(context, sug.surah, sug.verse),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════
// Suggestion tile
// ════════════════════════════════════════════════════

class _SuggestionTile extends StatelessWidget {
  final _AyahSuggestion suggestion;
  final String query;
  final Color borderClr;
  final Color textClr;
  final Color accentClr;
  final Color subtitleClr;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.suggestion,
    required this.query,
    required this.borderClr,
    required this.textClr,
    required this.accentClr,
    required this.subtitleClr,
    required this.onTap,
  });

  String _strip(String t) => t
      .replaceAll(RegExp('[\u064B-\u065F]'), '')
      .replaceAll(RegExp('[\u06D6-\u06ED]'), '')
      .replaceAll(RegExp('[\u0610-\u061A]'), '')
      .trim();

  @override
  Widget build(BuildContext context) {
    final verseText  = quran.getVerse(suggestion.surah, suggestion.verse);
    final surahName  = quran.getSurahNameArabic(suggestion.surah);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderClr),
          color: accentClr.withValues(alpha: 0.03),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Surah + verse badge
            Column(
              children: [
                Container(
                  width: 42.w,
                  padding: EdgeInsets.symmetric(vertical: 5.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: accentClr.withValues(alpha: 0.10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        surahName,
                        style: AppTextStyles.madReg12(context, color: accentClr),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "آية ${suggestion.verse}",
                        style: AppTextStyles.madReg12(context, color: subtitleClr),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(width: 10.w),

            // Verse text with highlights
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightedText(
                    text: verseText,
                    query: query,
                    textClr: textClr,
                    accentClr: accentClr,
                    context: context,
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 11.sp, color: subtitleClr),
                      SizedBox(width: 4.w),
                      Text(
                        "اضغط لعرض التفسير",
                        style: AppTextStyles.madReg12(
                            context, color: subtitleClr),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.arrow_back_ios_rounded,
                size: 14.sp, color: accentClr),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// Highlighted text — matches query ignoring tashkeel
// ════════════════════════════════════════════════════

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final Color textClr;
  final Color accentClr;
  final BuildContext context;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.textClr,
    required this.accentClr,
    required this.context,
  });

  String _strip(String t) => t
      .replaceAll(RegExp('[\u064B-\u065F]'), '')
      .replaceAll(RegExp('[\u06D6-\u06ED]'), '')
      .replaceAll(RegExp('[\u0610-\u061A]'), '')
      .trim();

  String _normalize(String t) => t
      .replaceAll(RegExp('[أإآٱ\u0671]'), 'ا')
      .replaceAll('\u0670', 'ا')  // superscript alef (يَٰ → يا)
      .replaceAll(RegExp('[ىئ]'), 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و');

  /// Builds a map: stripped_index → original_index
  /// Because tashkeel chars exist in [original] but not in [stripped],
  /// a position in [stripped] does NOT equal the same position in [original].
  /// We need this map to slice the original text correctly for highlighting.
  List<int> _buildCharMap(String original, String stripped) {
    final map = <int>[];
    int si = 0;
    for (int oi = 0; oi < original.length && si < stripped.length; oi++) {
      if (original[oi] == stripped[si]) {
        map.add(oi);
        si++;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext _) {
    final stripped      = _strip(text);
    final normalizedText  = _normalize(stripped.toLowerCase());
    final normalizedQuery = _normalize(_strip(query).toLowerCase());

    if (normalizedQuery.isEmpty || !normalizedText.contains(normalizedQuery)) {
      return Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.arsura17(context, color: textClr),
      );
    }

    // Map: position in stripped/normalized → position in original (with tashkeel)
    final charMap = _buildCharMap(text, stripped);

    /// Converts a stripped-text index to the corresponding original-text index.
    int toOrig(int strippedIdx) {
      if (strippedIdx >= charMap.length) return text.length;
      return charMap[strippedIdx];
    }

    final spans   = <TextSpan>[];
    int searchFrom = 0; // cursor in normalized/stripped space

    while (searchFrom <= normalizedText.length) {
      final matchIdx = normalizedText.indexOf(normalizedQuery, searchFrom);
      if (matchIdx == -1) {
        // Remaining text after last match
        final origStart = toOrig(searchFrom);
        if (origStart < text.length) {
          spans.add(TextSpan(
            text: text.substring(origStart),
            style: AppTextStyles.arsura17(context, color: textClr),
          ));
        }
        break;
      }

      // Normal text before this match
      if (matchIdx > searchFrom) {
        spans.add(TextSpan(
          text: text.substring(toOrig(searchFrom), toOrig(matchIdx)),
          style: AppTextStyles.arsura17(context, color: textClr),
        ));
      }

      // Highlighted match — slice original using mapped positions
      final matchEnd    = matchIdx + normalizedQuery.length;
      final origMatchStart = toOrig(matchIdx);
      final origMatchEnd   = matchEnd < charMap.length
          ? charMap[matchEnd - 1] + 1  // one past last matched original char
          : text.length;

      spans.add(TextSpan(
        text: text.substring(origMatchStart, origMatchEnd),
        style: AppTextStyles.arsura17(context, color: accentClr).copyWith(
          fontWeight: FontWeight.bold,
          backgroundColor: accentClr.withValues(alpha: 0.12),
        ),
      ));

      searchFrom = matchEnd;
      if (searchFrom >= normalizedText.length) break;
    }

    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }
}

// ════════════════════════════════════════════════════
// Data model
// ════════════════════════════════════════════════════

class _AyahSuggestion {
  final int surah;
  final int verse;
  const _AyahSuggestion({required this.surah, required this.verse});
}