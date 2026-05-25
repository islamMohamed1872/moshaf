// lib/views/quran/audio_screen.dart
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/controllers/quran_audio/audio_quran_cubit.dart';
import 'package:moshaf/controllers/quran_audio/audio_quran_states.dart';
import 'package:moshaf/controllers/text_quran/text_quran_cubit.dart';
import 'package:moshaf/views/quran/playlist_screen.dart';
import 'package:moshaf/views/quran/widgets/custom_sorah_container.dart';
import 'package:quran/quran.dart';
import 'package:quran/quran.dart' as quran;

import '../../components/audio_service.dart';
import '../../components/components.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';
import 'widgets/quran_page.dart';

class AudioScreen extends StatelessWidget {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeCubit.get(context).isDark;
    final gold   = AppColors.isGoldMode;

    final borderClr      = gold ? const Color(AppColors.goldBorder)   : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);
    final primaryTextClr = gold ? const Color(AppColors.goldText)      : (isDark ? Colors.white : Colors.black);
    final subtitleClr    = gold ? const Color(AppColors.goldText)      : (isDark ? Color(AppColors.lightBlack) : const Color(0xff848484));
    final iconClr        = gold ? const Color(AppColors.goldPrimary)   : (isDark ? Colors.white : Colors.black);
    final sliderActive   = gold ? const Color(AppColors.goldPrimary)   : (isDark ? Colors.white : Colors.black);
    final sliderInactive = gold ? const Color(AppColors.goldBorder)    : (isDark ? HexColor("#3E3E3E") : HexColor("#BFBFBF"));
    final primary        = AppColors.lbPrimary();

    return BlocConsumer<AudioQuranCubit, AudioQuranStates>(
      builder: (context, state) {
        final cubit = AudioQuranCubit.get(context);
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [

                  // ── top nav ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 20.0, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () async {
                            cubit.stop();
                            await AudioServices().player.clearAudioSources();
                            navigateTo(
                              context,
                              QuranViewPage(
                                navigatedFromRecitation: false,
                                shouldHighlightText: false,
                                highlightVerse: "",
                                jsonData: TextQuranCubit.get(context).suraJsonData,
                                pageNumber: getPageNumber(cubit.sorahNumber, 1),
                              ),
                            );
                          },
                          child: Icon(FontAwesomeIcons.fileLines, color: iconClr),
                        ),
                        InkWell(
                          onTap: () async { cubit.stop(); Navigator.pop(context); },
                          child: Container(
                            width: 30.w, height: 30.w,
                            padding: EdgeInsetsDirectional.only(
                              start: context.locale.languageCode == "ar" ? 0 : 7.w,
                              top: 5, bottom: 5,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: borderClr),
                            ),
                            child: FittedBox(
                              child: Icon(
                                context.locale.languageCode == "ar"
                                    ? Icons.arrow_forward_ios
                                    : Icons.arrow_back_ios,
                                color: iconClr,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // ── player card ──────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: EdgeInsetsDirectional.symmetric(
                        horizontal: 30.w, vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderClr),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20,),
                        RichText(
                          text: TextSpan(
                            text: cubit.sorahNumber.toString(),
                            style: AppTextStyles.arsura40(context,
                                color: primaryTextClr),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${quran.getPlaceOfRevelation(cubit.sorahNumber) == "Makkah" ? "مكية" : "مدنية"}"
                              " | ${quran.getVerseCount(cubit.sorahNumber)} ايات",
                          style: AppTextStyles.madXL10(context,
                              color: subtitleClr),
                        ),
                        SizedBox(height: 30.h),
                        _buildProgressBar(
                            cubit, context, isDark, gold,
                            sliderActive, sliderInactive),
                        _buildControls(cubit, state, isDark, gold),
                        SizedBox(height: 6.h),
                        _buildRepeatRow(
                            context, cubit, isDark, gold, primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ── reciter selector ─────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: borderClr),
                    ),
                    child: InkWell(
                      onTap: () => cubit.openReciterSelector(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cubit.selectedReciter?.name ?? 'اختر القارئ',
                              style: AppTextStyles.madReg14(context,
                                  color: primaryTextClr),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: primaryTextClr),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),

                  // ── surah list ────────────────────────────────────────────
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsetsDirectional.only(bottom: 70),
                      itemCount: 114,
                      separatorBuilder: (_, __) => SizedBox(height: 7.h),
                      itemBuilder: (context, index) {
                        final surahNumber = index + 1;
                        return CustomSorahContainer(
                          isDark: isDark,
                          borderColor: gold
                              ? const Color(AppColors.goldBorder)
                              : null,
                          placeOfRevelation:
                          quran.getPlaceOfRevelation(surahNumber) ==
                              "Makkah"
                              ? "مكية"
                              : "مدنية",
                          verseCount: quran.getVerseCount(surahNumber),
                          sorahIndex: index,
                          onRowPressed: () {
                            cubit.sorahNumber = surahNumber;
                            cubit.stop();
                            cubit.play();
                            TextQuranCubit.get(context).soraNumber =
                                surahNumber;
                          },
                          onReadPressed: () async {
                            cubit.stop();
                            await AudioServices().player.clearAudioSources();
                            TextQuranCubit.get(context).soraNumber =
                                surahNumber;
                            navigateTo(
                              context,
                              QuranViewPage(
                                navigatedFromRecitation: false,
                                shouldHighlightText: false,
                                highlightVerse: "",
                                jsonData: TextQuranCubit.get(context)
                                    .suraJsonData,
                                pageNumber: getPageNumber(surahNumber, 1),
                              ),
                            );
                          },
                          onListenPressed: () {
                            cubit.sorahNumber = surahNumber;
                            cubit.stop();
                            cubit.play();
                            TextQuranCubit.get(context).soraNumber =
                                surahNumber;
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlaylistScreen()),
            ),
            backgroundColor: primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.playlist_play),
            label: Text('قائمتي',
                style: AppTextStyles.madReg12(context, color: Colors.white)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        );
      },
      listener: (_, __) {},
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildProgressBar(
      AudioQuranCubit cubit,
      BuildContext context,
      bool isDark,
      bool gold,
      Color sliderActive,
      Color sliderInactive,
      ) {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 1,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: SliderComponentShape.noOverlay,
        ),
        child: Slider(
          activeColor: sliderActive,
          inactiveColor: sliderInactive,
          value: cubit.position.inSeconds
              .clamp(0, cubit.duration.inSeconds)
              .toDouble(),
          max: cubit.duration.inSeconds.toDouble().clamp(1, double.infinity),
          onChangeEnd: (_) => cubit.play(),
          onChanged: (v) =>
              cubit.seekTo(Duration(seconds: v.toInt())),
        ),
      ),
    );
  }

  Widget _buildControls(
      AudioQuranCubit cubit,
      AudioQuranStates state,
      bool isDark,
      bool gold,
      ) {
    final circleClr =
    gold ? const Color(AppColors.goldPrimary) : (isDark ? Colors.white : Colors.black);
    final iconClr   = isDark ? Colors.black : Colors.white;
    final stepClr   =
    gold ? const Color(AppColors.goldPrimary) : (isDark ? Colors.white : Colors.black);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(FontAwesomeIcons.forwardStep, size: 20, color: stepClr),
          onPressed: cubit.canGoPrev ? cubit.prevSurah : null,
        ),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: () {
            if (state is! GetDataLoadingState) cubit.play();
          },
          child: CircleAvatar(
            radius: 20,
            backgroundColor: circleClr,
            child: state is GetDataLoadingState &&
                cubit.duration == Duration.zero
                ? Padding(
              padding: const EdgeInsets.all(2),
              child: CircularProgressIndicator(
                color: gold
                    ? Colors.black
                    : (isDark ? Colors.black : Colors.white),
              ),
            )
                : Icon(
              cubit.isPlaying ? Icons.pause : Icons.play_arrow,
              color: iconClr,
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 30),
        IconButton(
          icon: Icon(FontAwesomeIcons.backwardStep, size: 20, color: stepClr),
          onPressed: cubit.canGoNext ? cubit.nextSurah : null,
        ),
      ],
    );
  }

  // ── repeat row ──────────────────────────────────────────────────────────────
  Widget _buildRepeatRow(BuildContext context, AudioQuranCubit cubit,
      bool isDark, bool gold, Color primary) {
    final dimClr =
    (isDark ? Colors.white : Colors.black).withOpacity(0.28);

    IconData icon;
    String label;
    Color color;

    switch (cubit.repeatMode) {
      case RepeatMode.surah:
        icon  = Icons.repeat_one_rounded;
        label = 'تكرار السورة';
        color = primary;
        break;
      case RepeatMode.range:
        icon  = Icons.repeat_rounded;
        label = 'تكرار ${cubit.repeatStartVerse}–${cubit.repeatEndVerse}';
        color = primary;
        break;
      default:
        icon  = Icons.repeat_rounded;
        label = 'بدون تكرار';
        color = dimClr;
    }

    return GestureDetector(
      onTap: () =>
          _showRepeatSheet(context, cubit, isDark, gold, primary),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 6.w),
            Text(label,
                style: AppTextStyles.madReg12(context, color: color)),
          ],
        ),
      ),
    );
  }

  // ── repeat mode sheet ───────────────────────────────────────────────────────
  void _showRepeatSheet(BuildContext context, AudioQuranCubit cubit,
      bool isDark, bool gold, Color primary) {
    final bgColor   = gold ? const Color(AppColors.goldBackground) : (isDark ? const Color(0xFF151515) : Colors.white);
    final borderClr = gold ? const Color(AppColors.goldBorder)     : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);
    final textClr   = gold ? const Color(AppColors.goldText)       : (isDark ? Colors.white : Colors.black);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocBuilder<AudioQuranCubit, AudioQuranStates>(
        builder: (ctx, __) {
          final c = AudioQuranCubit.get(ctx);
          return Container(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border.all(color: borderClr),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w, height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                      color: borderClr,
                      borderRadius: BorderRadius.circular(2)),
                ),
                Text('خيارات التكرار',
                    style: AppTextStyles.madB16(ctx, color: textClr)),
                SizedBox(height: 20.h),
                _RepeatOptionTile(
                  icon: Icons.repeat_rounded,
                  label: 'بدون تكرار',
                  selected: c.repeatMode == RepeatMode.none,
                  primary: primary, borderClr: borderClr, textClr: textClr,
                  onTap: () {
                    c.stopRangeLoop();
                    c.setRepeatMode(RepeatMode.none);
                    Navigator.pop(ctx);
                  },
                ),
                SizedBox(height: 10.h),
                _RepeatOptionTile(
                  icon: Icons.repeat_one_rounded,
                  label: 'تكرار السورة كاملة',
                  selected: c.repeatMode == RepeatMode.surah,
                  primary: primary, borderClr: borderClr, textClr: textClr,
                  onTap: () {
                    c.stopRangeLoop();
                    c.setRepeatMode(RepeatMode.surah);
                    Navigator.pop(ctx);
                  },
                ),
                SizedBox(height: 10.h),
                _RepeatOptionTile(
                  icon: Icons.repeat_rounded,
                  label: 'تكرار نطاق آيات',
                  selected: c.repeatMode == RepeatMode.range,
                  primary: primary, borderClr: borderClr, textClr: textClr,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRangePicker(context, c, isDark, gold, primary);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── range picker sheet (opens _RangePickerSheet StatefulWidget) ─────────────
  void _showRangePicker(BuildContext context, AudioQuranCubit cubit,
      bool isDark, bool gold, Color primary) {
    final maxVerses = quran.getVerseCount(cubit.sorahNumber);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RangePickerSheet(
        maxVerses: maxVerses,
        initStart: 1,            // default → first verse
        initEnd:   maxVerses,    // default → last verse
        isDark:    isDark,
        gold:      gold,
        primary:   primary,
        surahName: quran.getSurahNameArabic(cubit.sorahNumber),
        onConfirm: (start, end) {
          cubit.setRepeatRange(start: start, end: end);
          cubit.stopRangeLoop();
          cubit.startRangeLoop();
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _RangePickerSheet — StatefulWidget manages +/- stepper state locally
// ══════════════════════════════════════════════════════════════════════════════

class _RangePickerSheet extends StatefulWidget {
  final int maxVerses;
  final int initStart;
  final int initEnd;
  final bool isDark;
  final bool gold;
  final Color primary;
  final String surahName;
  final void Function(int start, int end) onConfirm;

  const _RangePickerSheet({
    required this.maxVerses,
    required this.initStart,
    required this.initEnd,
    required this.isDark,
    required this.gold,
    required this.primary,
    required this.surahName,
    required this.onConfirm,
  });

  @override
  State<_RangePickerSheet> createState() => _RangePickerSheetState();
}

class _RangePickerSheetState extends State<_RangePickerSheet> {
  late int start;
  late int end;

  @override
  void initState() {
    super.initState();
    start = widget.initStart; // 1
    end   = widget.initEnd;   // maxVerses
  }

  void _incStart() { if (start < end)              setState(() => start++); }
  void _decStart() { if (start > 1)                setState(() => start--); }
  void _incEnd()   { if (end < widget.maxVerses)   setState(() => end++); }
  void _decEnd()   { if (end > start)              setState(() => end--); }

  @override
  Widget build(BuildContext context) {
    final bgColor   = widget.gold ? const Color(AppColors.goldBackground) : (widget.isDark ? const Color(0xFF151515) : Colors.white);
    final borderClr = widget.gold ? const Color(AppColors.goldBorder)     : Color(widget.isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);
    final textClr   = widget.gold ? const Color(AppColors.goldText)       : (widget.isDark ? Colors.white : Colors.black);
    final dimClr    = textClr.withOpacity(0.45);
    final p         = widget.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: borderClr),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // handle
          Container(
            width: 40.w, height: 4.h,
            margin: EdgeInsets.only(bottom: 18.h),
            decoration: BoxDecoration(
                color: borderClr,
                borderRadius: BorderRadius.circular(2)),
          ),

          Text('حدد نطاق الآيات للتكرار',
              style: AppTextStyles.madB16(context, color: textClr)),
          SizedBox(height: 4.h),
          Text(
            'سورة ${widget.surahName}  •  ( ١ – ${widget.maxVerses} )',
            style: AppTextStyles.madReg12(context, color: dimClr),
          ),
          SizedBox(height: 28.h),

          // ── two steppers side by side ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _VerseStepper(
                  label: 'من الآية',
                  value: start,
                  onInc: _incStart,
                  maxVerse: widget.maxVerses,
                  onDec: _decStart,
                  canInc: start < end,
                  canDec: start > 1,
                  primary: p,
                  borderClr: borderClr,
                  textClr: textClr,
                  dimClr: dimClr,
                  isDark: widget.isDark,
                  gold: widget.gold,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _VerseStepper(
                  label: 'إلى الآية',
                  value: end,
                  maxVerse: widget.maxVerses,
                  onInc: _incEnd,
                  onDec: _decEnd,
                  canInc: end < widget.maxVerses,
                  canDec: end > start,
                  primary: p,
                  borderClr: borderClr,
                  textClr: textClr,
                  dimClr: dimClr,
                  isDark: widget.isDark,
                  gold: widget.gold,
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // ── summary chip ───────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: p.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.repeat_rounded, size: 14, color: p),
                SizedBox(width: 8.w),
                Text(
                  'تكرار الآيات  $start – $end  (${end - start + 1} آية)',
                  style: AppTextStyles.madReg12(context, color: p),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // ── confirm ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: p,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onConfirm(start, end);
              },
              child: Text('بدء التكرار',
                  style: AppTextStyles.madB14(context,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _VerseStepper  —  label  +  [−]  value  [+]
// ══════════════════════════════════════════════════════════════════════════════

class _VerseStepper extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final bool canInc;
  final bool canDec;
  final Color primary;
  final Color borderClr;
  final Color textClr;
  final Color dimClr;
  final bool isDark;
  final bool gold;
  final int maxVerse;
  const _VerseStepper({
    required this.label,
    required this.value,
    required this.onInc,
    required this.onDec,
    required this.canInc,
    required this.canDec,
    required this.primary,
    required this.borderClr,
    required this.textClr,
    required this.dimClr,
    required this.isDark,
    required this.gold, required this.maxVerse,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = gold
        ? const Color(0xffFFF7E6)
        : (isDark ? const Color(0xff222222) : const Color(0xffF8F8F8));

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderClr),
      ),
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.madReg10(context, color: dimClr)),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepBtn(
                icon: Icons.remove_rounded,
                enabled: canDec,
                primary: primary,
                borderClr: borderClr,
                onTap: onDec,
              ),
              GestureDetector(
                onTap: () async {

                  final controller = TextEditingController(
                    text: value.toString(),
                  );

                  final result = await showDialog<int>(
                    context: context,
                    builder: (_) {

                      final isGold = AppColors.isGoldMode;

                      final bgColor = isGold
                          ? const Color(0xffFFF8E7)
                          : AppColors.lbBg(context);

                      final borderColor = isGold
                          ? const Color(AppColors.goldBorder)
                          : AppColors.lbBorder(context);

                      final textColor = isGold
                          ? const Color(0xff4E3B26)
                          : AppColors.lbText(context);

                      final primaryColor = AppColors.lbPrimary();

                      final subPanel = isGold
                          ? const Color(0xffF8ECD1)
                          : AppColors.lbSubPanel(context);

                      final hintColor = isGold
                          ? const Color(0xff9E7B4F)
                          : textColor.withOpacity(0.45);

                      return AlertDialog(
                        backgroundColor: bgColor,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: borderColor,
                          ),
                        ),

                        titlePadding: EdgeInsets.fromLTRB(
                          24.w,
                          22.h,
                          24.w,
                          10.h,
                        ),

                        contentPadding: EdgeInsets.fromLTRB(
                          24.w,
                          0,
                          24.w,
                          10.h,
                        ),

                        actionsPadding: EdgeInsets.fromLTRB(
                          16.w,
                          0,
                          16.w,
                          16.h,
                        ),

                        title: Row(
                          children: [

                            Icon(
                              Icons.auto_stories_rounded,
                              color: isGold
                                  ? const Color(0xffB8860B)
                                  : primaryColor,
                              size: 22.sp,
                            ),

                            SizedBox(width: 10.w),

                            Text(
                              "اختر رقم الآية",
                              style: AppTextStyles.madB16(
                                context,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),

                        content: Container(
                          decoration: BoxDecoration(
                            gradient: isGold
                                ? LinearGradient(
                              colors: [
                                const Color(0xffF6E7C8),
                                const Color(0xffFFF4DD),
                              ],
                            )
                                : null,

                            color: isGold ? null : subPanel,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor.withOpacity(0.6),
                            ),
                          ),

                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            autofocus: true,

                            style: AppTextStyles.madB20(
                              context,
                              color: isGold
                                  ? const Color(0xffB8860B)
                                  : primaryColor,
                            ),

                            textAlign: TextAlign.center,

                            decoration: InputDecoration(
                              hintText: "1 - $maxVerse",

                              hintStyle: TextStyle(
                                color: hintColor,
                                fontSize: 15.sp,
                              ),

                              border: InputBorder.none,

                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 18.h,
                              ),
                            ),
                          ),
                        ),

                        actions: [

                          TextButton(
                            onPressed: () => Navigator.pop(context),

                            child: Text(
                              "إلغاء",
                              style: AppTextStyles.madReg14(
                                context,
                                color: hintColor,
                              ),
                            ),
                          ),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,

                              elevation: 0,

                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 12.h,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),

                            onPressed: () {

                              final number =
                              int.tryParse(controller.text);

                              if (number == null) return;

                              Navigator.pop(
                                context,
                                number.clamp(1, maxVerse),
                              );
                            },

                            child: Text(
                              "تأكيد",
                              style: AppTextStyles.madB14(
                                context,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (result == null) return;

                  final diff = result - value;

                  if (diff > 0) {
                    for (int i = 0; i < diff; i++) {
                      if (canInc) onInc();
                    }
                  } else {
                    for (int i = 0; i < diff.abs(); i++) {
                      if (canDec) onDec();
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 74.w,
                  padding: EdgeInsets.symmetric(
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primary.withOpacity(0.35),
                    ),
                    color: primary.withOpacity(
                      gold ? 0.12 : 0.08,
                    ),
                  ),
                  child: Text(
                    value.toString(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.madB20(
                      context,
                      color: primary,
                    ),
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.add_rounded,
                enabled: canInc,
                primary: primary,
                borderClr: borderClr,
                onTap: onInc,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── +/- circle button ──────────────────────────────────────────────────────────
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color primary;
  final Color borderClr;
  final VoidCallback onTap;

  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.primary,
    required this.borderClr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final clr = enabled ? primary : borderClr;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32.w, height: 32.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: clr),
          color: enabled ? primary.withOpacity(0.1) : Colors.transparent,
        ),
        child: Icon(icon, size: 16, color: clr),
      ),
    );
  }
}

// ── repeat option tile ─────────────────────────────────────────────────────────
class _RepeatOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color primary;
  final Color borderClr;
  final Color textClr;
  final VoidCallback onTap;

  const _RepeatOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.primary,
    required this.borderClr,
    required this.textClr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg  = selected ? primary.withOpacity(0.1) : Colors.transparent;
    final clr = selected ? primary : textClr;
    final bdr = selected ? primary : borderClr;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bdr),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: clr),
            SizedBox(width: 12.w),
            Text(label,
                style: AppTextStyles.madReg14(context, color: clr)),
            const Spacer(),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 18, color: primary),
          ],
        ),
      ),
    );
  }
}