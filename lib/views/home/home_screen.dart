import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/home/home_cubit.dart';
import 'package:moshaf/controllers/home/home_states.dart';
import 'package:moshaf/controllers/prayer_times/prayer_times_cubit.dart';
import 'package:moshaf/controllers/prayer_times/prayer_times_states.dart';
import 'package:moshaf/views/home/widgets/animated_prayer_container.dart';
import 'package:moshaf/views/rafeq/rafeq_intro_screen.dart';
import 'package:moshaf/views/settings/settings_screen.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../controllers/azkar/azkar_cubit.dart';
import '../../controllers/recitation/recitation_cubit.dart';
import '../../controllers/recitation/recitation_state.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../quran/quran_main_screen.dart';
import '../recitation/recitation_screen.dart';
import '../widgets/custom_green_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GlobalKey _prayerKey;
  late final GlobalKey _rafeqCarouselKey;
  late final GlobalKey _zekrKey;
  late final GlobalKey _allahNameKey;
  late final GlobalKey _settingsKey;
  late final List<GlobalKey> _gridKeys;

  double _rafeqX = 20;
  double _rafeqY = 300;
  bool _rafeqExpanded = false;
  // Carousel page controller
  late final PageController _carouselController;
  int _currentCarouselPage = 0;

  @override
  void initState() {
    super.initState();

    _prayerKey = GlobalKey();
    _rafeqCarouselKey = GlobalKey();
    _zekrKey = GlobalKey();
    _allahNameKey = GlobalKey();
    _settingsKey = GlobalKey();
    _carouselController = PageController();

    final cubit = HomeCubit.get(context);
    _gridKeys = List.generate(cubit.gridItems.length, (_) => GlobalKey());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = HomeCubit.get(context);
      await cubit.getFirstTime();
      await cubit.loadRafeqVisibility();
      await cubit.loadDailyAyah();
      await cubit.loadDailyHadith();
      if (cubit.isFirstTime == true) {
        cubit.startTutorial();
      }
    });
  }

  @override
  void dispose() {
    _carouselController.dispose();
    HomeCubit.get(context).closeCoach();
    super.dispose();
  }

  // ====================== Tutorial Helpers ======================

  TargetFocus _buildTargetForIndex(
      BuildContext context,
      bool isDark,
      HomeCubit cubit,
      )
  {
    final gold = AppColors.isGoldMode;
    final titleClr = gold ? const Color(AppColors.goldAccent) : Colors.white;
    final descClr = Colors.white.withOpacity(0.9);

    final gridCount = cubit.gridItems.length;
    const gridStartIndex = 3;
    final allahNameIndex = gridStartIndex + gridCount;
    final settingsIndex = allahNameIndex + 1;

    GlobalKey targetKey;
    String identify;
    ContentAlign align = ContentAlign.top;

    if (cubit.tutorialIndex == 0) {
      targetKey = _prayerKey;
      identify = "prayer";
      align = ContentAlign.bottom;
    } else if (cubit.tutorialIndex == 1) {
      targetKey = _rafeqCarouselKey;
      identify = "rafeq_carousel";
    } else if (cubit.tutorialIndex == 2) {
      targetKey = _zekrKey;
      identify = "zekr_today";
    } else if (cubit.tutorialIndex >= gridStartIndex &&
        cubit.tutorialIndex < allahNameIndex) {
      final gridIndex = cubit.tutorialIndex - gridStartIndex;
      targetKey = _gridKeys[gridIndex];
      identify = "grid_$gridIndex";
    } else if (cubit.tutorialIndex == allahNameIndex) {
      targetKey = _allahNameKey;
      identify = "allah_names";
    } else {
      targetKey = _settingsKey;
      identify = "settings";
    }

    return TargetFocus(
      identify: identify,
      keyTarget: targetKey,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: align,
          child: _CoachContent(
            title: cubit.coachContent[cubit.tutorialIndex]['title']!,
            description: cubit.coachContent[cubit.tutorialIndex]['content']!,
            titleColor: titleClr,
            descColor: descClr,
          ),
        ),
      ],
    );
  }

  Future<void> _scrollToStep(HomeCubit cubit) async {
    final gridCount = cubit.gridItems.length;
    const gridStartIndex = 3;
    final allahNameIndex = gridStartIndex + gridCount;

    BuildContext? ctx;

    if (cubit.tutorialIndex == 0) {
      ctx = _prayerKey.currentContext;
    } else if (cubit.tutorialIndex == 1) {
      ctx = _rafeqCarouselKey.currentContext;
    } else if (cubit.tutorialIndex == 2) {
      ctx = _zekrKey.currentContext;
    } else if (cubit.tutorialIndex >= gridStartIndex &&
        cubit.tutorialIndex < allahNameIndex) {
      ctx = _gridKeys[cubit.tutorialIndex - gridStartIndex].currentContext;
    } else if (cubit.tutorialIndex == allahNameIndex) {
      ctx = _allahNameKey.currentContext;
    } else {
      ctx = _settingsKey.currentContext;
    }

    if (ctx == null) return;

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.25,
    );

    await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _scrollToTop(HomeCubit cubit) async {
    if (!cubit.homeScrollController.hasClients) return;

    await cubit.homeScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );

    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _showCoach(
      BuildContext context, HomeCubit cubit, bool isDark) async
  {
    await _scrollToStep(cubit);

    final target = _buildTargetForIndex(context, isDark, cubit);
    final lastIndex = cubit.gridItems.length + 4;

    cubit.activeCoach = TutorialCoachMark(
      targets: [target],
      colorShadow: Colors.black.withOpacity(0.85),
      textSkip: "تخطي",
      paddingFocus: 12,
      opacityShadow: 0.8,
      onFinish: () {
        if (!cubit.tutorialRunning) return;

        if (cubit.tutorialIndex >= lastIndex) {
          cubit.finishTutorial();
          _showFirstTimeDialog(context, cubit, isDark);
          _scrollToTop(cubit);
        } else {
          cubit.requestNextStep();
        }
      },
      onSkip: () {
        cubit.finishTutorial();
        _showFirstTimeDialog(context, cubit, isDark);
        _scrollToTop(cubit);
        return true;
      },
    );

    cubit.activeCoach!.show(context: context);
  }

  // ====================== Dialog ======================

  void _showFirstTimeDialog(
      BuildContext context,
      HomeCubit cubit,
      bool isDark,
      )
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding:
        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: Color(
              isDark
                  ? AppColors.containerDarkBorders
                  : AppColors.containerLightBorders,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(15.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    cubit.setFirstTime();
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: const BoxDecoration(
                      color: Color(0xff353535),
                      shape: BoxShape.circle,
                    ),
                    child:
                    const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsetsDirectional.only(
                  start: 25.w,
                  end: 25.w,
                  top: 40.h,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff0F9D58),
                  borderRadius: BorderRadius.circular(15),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  "assets/images/mostakeem_preview.png",
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 30.h),
              Text(
                "اهدنا الصراط المستقيم",
                style:
                AppTextStyles.madB20(context).copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              CustomGreenButton(
                text: "ابدأ الآن",
                onTap: () {
                  Navigator.pop(context);
                  cubit.setFirstTime();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================== Rafeq Carousel ======================

  /// Builds the list of carousel slides based on recitation state.
  List<_CarouselSlide> _buildCarouselSlides(
      RecitationCubit recitationCubit,
      PrayerTimesCubit prayerCubit,
      bool gold,
      BuildContext context,
      )
  {
    final slides = <_CarouselSlide>[];

    // ── Slide 1: Dynamic contextual reminder ──
    slides.add(_buildContextualSlide(context, prayerCubit, gold));

    // ── Slide 2: Recitation / Rafeq status (unchanged) ──
    if (!recitationCubit.hasActiveGoal) {
      slides.add(_CarouselSlide(
        imagePath: 'assets/images/rafeq_reading.png',
        message: 'لم تحدد وردك اليومي بعد!\nاضغط هنا لتبدأ رحلتك مع القرآن',
        gold: gold,
        onTap: () => navigateTo(context, RecitationScreen()),
        badgeText: null,
        badgeColor: null,
      ));
    } else if (recitationCubit.isTodayCompleted) {
      slides.add(_CarouselSlide(
        imagePath: 'assets/images/rafeq_excited.png',
        message: 'أحسنت! أتممت وردك اليوم\nاستمر على هذا النهج',
        gold: gold,
        onTap: () => navigateTo(context, RecitationScreen()),
        badgeText: 'أتممت اليوم',
        badgeColor: Colors.green,
      ));
    } else {
      slides.add(_CarouselSlide(
        imagePath: 'assets/images/rafeq_sad.png',
        message:
        'لم تكمل وردك اليوم بعد\nتبقى لك ${recitationCubit.todayPagesRemaining} صفحة، هيا!',
        gold: gold,
        onTap: () => navigateTo(context, RecitationScreen()),
        badgeText: recitationCubit.daysLate > 0
            ? 'متأخر ${recitationCubit.daysLate} يوم'
            : null,
        badgeColor: Colors.red,
      ));
    }


    return slides;
  }

  /// Returns the second carousel slide based on current time / prayer context.
  _CarouselSlide _buildContextualSlide(
      BuildContext context,
      PrayerTimesCubit prayerCubit,
      bool gold,
      )
  {
    final now = DateTime.now();
    final times = prayerCubit.prayerTimes;

    // ── Priority 1: Late night (after 1 AM until Fajr) ──
    if (now.hour >= 1 && now.hour < 4) {
      return _CarouselSlide(
        imagePath: 'assets/images/rafeq_sleep.png',
        message: 'الوقت متأخر 😴\nحاول تنام بدري علشان صلاة الفجر',
        gold: gold,
        onTap: null,
        badgeText: null,
        badgeColor: null,
      );
    }

    if (times.isNotEmpty) {
      // ── Priority 2: Just after a prayer (within 20 min) ──
      const skipKeys = {'الشروق', 'منتصف الليل', 'الثلث الاخير'};
      for (final entry in times.entries) {
        if (skipKeys.contains(entry.key)) continue;
        final diff = now.difference(entry.value).inMinutes;
        if (diff >= 0 && diff <= 20) {
          return _CarouselSlide(
            imagePath: 'assets/images/rafeq_pray.png',
            message: 'صليت ${entry.key}؟ 🌿\nماتنساش أذكار بعد الصلاة',
            gold: gold,
            onTap: () => AzkarCubit.get(context)
                .navigateToRelatedAzkarScreen(context, 'أذكار بعد الصلاة'),
            badgeText: 'بعد الصلاة',
            badgeColor: const Color(0xFF0F9D58),
          );
        }
      }

      // ── Priority 3: Pre-Adhan (within 10 min before any prayer) ──
      for (final entry in times.entries) {
        if (skipKeys.contains(entry.key)) continue;
        final minsLeft = entry.value.difference(now).inMinutes;
        if (minsLeft >= 0 && minsLeft <= 10) {
          return _CarouselSlide(
            imagePath: 'assets/images/rafeq_pray.png',
            message: 'الأذان اقترب 🕌\nاستعد لصلاة ${entry.key}',
            gold: gold,
            onTap: null,
            badgeText: 'بعد $minsLeft دقيقة',
            badgeColor: Colors.orange,
          );
        }
      }


      // ── Priority 4: Morning – after Fajr until Dhuhr ──
      final fajr  = times['الفجر'];
      final dhuhr = times['الظهر'];
      if (fajr != null && dhuhr != null &&
          now.isAfter(fajr) && now.isBefore(dhuhr)) {
        return _CarouselSlide(
          imagePath: 'assets/images/rafeq_morning.png',
          message: 'صباح الخير 🌤️\nابدأ يومك بأذكار الصباح',
          gold: gold,
          onTap: () => AzkarCubit.get(context)
              .navigateToRelatedAzkarScreen(context, 'أذكار الصباح'),
          badgeText: null,
          badgeColor: null,
        );
      }

      // Between Dhuhr and Asr ──
      final asr = times['العصر'];

      if (dhuhr != null &&
          asr != null &&
          now.isAfter(dhuhr) &&
          now.isBefore(asr)) {
        return _CarouselSlide(
          imagePath: 'assets/images/rafeq_reading.png',
          message:
          'وقت هادي بعد الظهر 📖\nاقرأ وردك أو خُد دقيقة ذكر قبل العصر',
          gold: gold,
          onTap: () => navigateTo(context, RecitationScreen()),
          badgeText: null,
          badgeColor: null,
        );
      }

      // Between Asr and Maghrib
      final maghrib = times['المغرب'];

      if (asr != null &&
          maghrib != null &&
          now.isAfter(asr) &&
          now.isBefore(maghrib)) {
        final minsLeftToMaghrib = maghrib.difference(now).inMinutes;

        return _CarouselSlide(
          imagePath: 'assets/images/rafeq_pray.png',
          message:
          'وقت جميل لأذكار المساء 🌅\nباقي على المغرب $minsLeftToMaghrib دقيقة',
          gold: gold,
          onTap: () => AzkarCubit.get(context)
              .navigateToRelatedAzkarScreen(context, 'أذكار المساء'),
          badgeText: 'قبل المغرب',
          badgeColor: const Color(0xFFD4AF37),
        );
      }

      // ── Priority 5: Evening – after Maghrib ──
      final isha    = times['العشاء'];
      if (maghrib != null && isha != null && now.isAfter(maghrib)) {
        return _CarouselSlide(
          imagePath: 'assets/images/rafeq_sleep.png',
          message: 'يومك كان طويل 🤍\nخُد دقيقة لأذكار المساء',
          gold: gold,
          onTap: () => AzkarCubit.get(context)
              .navigateToRelatedAzkarScreen(context, 'أذكار المساء'),
          badgeText: null,
          badgeColor: null,
        );
      }
    }

    // ── Priority 6: Friday – Surah Al-Kahf ──
    if (now.weekday == DateTime.friday) {
      return _CarouselSlide(
        imagePath: 'assets/images/rafeq_reading.png',
        message: 'لا تنسَ سورة الكهف اليوم 🌿\nيوم الجمعة',
        gold: gold,
        onTap: () => navigateTo(context, QuranMainScreen()),
        badgeText: 'الجمعة',
        badgeColor: const Color(0xFF0F9D58),
      );
    }

    // ── Fallback: generic evening reminder ──
    return _CarouselSlide(
      imagePath: 'assets/images/rafeq_sleep.png',
      message: 'كان يوم طويل لازم نرتاح\nبس ماتنساش اذكار المساء',
      gold: gold,
      onTap: () => AzkarCubit.get(context)
          .navigateToRelatedAzkarScreen(context, 'أذكار المساء'),
      badgeText: null,
      badgeColor: null,
    );
  }

  Widget _buildRafeqCarousel(
      BuildContext context,
      bool gold,
      RecitationCubit recitationCubit,
      PrayerTimesCubit prayerCubit,
      )
  {
    final slides = _buildCarouselSlides(recitationCubit, prayerCubit, gold, context,);

    return Column(
      children: [
        SizedBox(
          height: 200.h,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _currentCarouselPage = i),
            itemBuilder: (context, index) {
              final slide = slides[index];
              return GestureDetector(
                onTap: slide.onTap,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    // color: Colors.red,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/rafeq_bg.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),

                      // Rafeq character
                      Positioned(
                        left: 35,
                        child: Image.asset(
                          slide.imagePath,
                          height: 150.h,
                          width: 100.w,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Message
                      Positioned(
                        right: 30,
                        left: 140.w,
                        child: Text(
                          slide.message,
                          style: AppTextStyles.madB16(
                            context,
                            color: gold
                                ? const Color(AppColors.goldAccent)
                                : Colors.white,
                          ),
                        ),
                      ),

                      // Tap hint arrow (only if tappable)
                      if (slide.onTap != null)
                        Positioned(
                          bottom: 12.h,
                          right: 16.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'اضغط للانتقال',
                                  style: AppTextStyles.madReg10(context,
                                      color: Colors.white),
                                ),
                                SizedBox(width: 4.w),
                                const Icon(Icons.arrow_forward_ios,
                                    color: Colors.white, size: 10),
                              ],
                            ),
                          ),
                        ),

                      // Status badge (e.g. "أتممت اليوم " or "متأخر X يوم")
                      if (slide.badgeText != null)
                        Positioned(
                          top: 10.h,
                          right: 12.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: slide.badgeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              slide.badgeText!,
                              style: AppTextStyles.madReg10(context,
                                  color: Colors.white),
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

        // Dots indicator
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (i) {
            final isActive = i == _currentCarouselPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: isActive ? 16.w : 6.w,
              height: 6.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isActive
                    ? (gold
                    ? const Color(AppColors.goldPrimary)
                    : Color(AppColors.mainGreen))
                    : Colors.grey.withOpacity(0.4),
              ),
            );
          }),
        ),
      ],
    );
  }
  // ====================== Random Zekr Section ======================

  Widget _buildZekrSection(
      BuildContext context,
      HomeCubit cubit,
      bool isDark,
      bool gold,
      )
  {
    final accentClr = gold
        ? const Color(AppColors.goldPrimary)
        : Color(AppColors.mainGreen);

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final subtitleClr = gold
        ? const Color(AppColors.goldText).withOpacity(0.6)
        : (isDark ? Colors.white54 : Colors.black38);

    return Container(
      padding: EdgeInsets.all(15),
      height: 130.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderClr),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Rafeq image anchored to the left ──
          Positioned(
            left: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/rafeq_pray.png',
              height: 100.h,
              width: 80.w,
              fit: BoxFit.contain,
            ),
          ),

          // ── Content: label + zekr text + refresh button ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section label row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Refresh button

                  // Label
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ذكر اليوم',
                        style: AppTextStyles.madB14(context, color: textClr),
                      ),
                      SizedBox(width: 6.w),
                      Icon(Icons.auto_awesome,
                          color: accentClr, size: 14.w),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 10.h),

              // Zekr text
              cubit.currentZekr.isEmpty
                  ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                      color: accentClr,
                      strokeWidth: 2,
                    ),
                  )
                  : Text(
                cubit.currentZekr,
                style: AppTextStyles.madReg14(context, color: textClr),
                textAlign: TextAlign.right,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 8.h),

              Row(
                spacing: 10,
                children: [
                  Text(
                    'اضغط ↺ لذكر جديد',
                    style: AppTextStyles.madReg12(context, color: subtitleClr),
                  ),
                  GestureDetector(
                    onTap: () async => cubit.loadRandomZekr(),
                    child: Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        color: accentClr.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: accentClr.withOpacity(0.3), width: 1),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: accentClr,
                        size: 16.w,
                      ),
                    ),
                  ),

                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====================== Allah Names Section ======================

  Widget _buildAllahNameSection(BuildContext context, HomeCubit cubit, bool isDark, bool gold) {
    final nameData = cubit.currentAllahName;
    if (nameData == null) return const SizedBox.shrink();

    final accentClr = gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen);
    // Always use a warm gold for the decorative elements regardless of mode
    const decorGold = Color(0xFFD4AF37);
    final goldClr = gold ? const Color(AppColors.goldPrimary) : decorGold;

    final panelFill = gold
        ? const Color(AppColors.goldBackground)
        : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF7F4EE));
    final panelBorder = gold
        ? const Color(AppColors.goldBorder)
        : (isDark ? const Color(0xFF3A3A3C) : decorGold);
    final nameClr = gold
        ? const Color(AppColors.goldPrimary)
        : (isDark ? const Color(0xFF5DBB7A) : const Color(0xFF1A6B35));
    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : const Color(0xFF2C2C2C));

    return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
      // ── Header row ──
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        // Title
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('تعريف بأسماء الله الحسني', style: AppTextStyles.madB16(context, color: textClr)),
          SizedBox(width: 6.w),
          Text('✦', style: TextStyle(color: goldClr, fontSize: 14.sp)),
        ]),
        // Refresh
        GestureDetector(
            onTap: cubit.loadRandomAllahName,
            child: Container(
                width: 32.w, height: 32.w,
                decoration: BoxDecoration(
                    color: accentClr.withOpacity(0.1), shape: BoxShape.circle,
                    border: Border.all(color: accentClr.withOpacity(0.3), width: 1)),
                child: Icon(Icons.refresh_rounded, color: accentClr, size: 16.w))),

      ]),

      SizedBox(height: 10.h),

      // ── Card: arch panel left + Rafeq right ──
      SizedBox(
        height: 195.h,
        child: Stack(
            clipBehavior: Clip.none, children: [

          // ── Arch-shaped panel ──
          Positioned(left: 0, right: 80.w, top: 0, bottom: 0,
              child: CustomPaint(
                painter: _ArchPanelPainter(fill: panelFill, border: panelBorder),
                child: Padding(
                  padding: EdgeInsets.only(top: 22.h, left: 14.w, right: 14.w, bottom: 12.h),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                    // Sparkles
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('✦', style: TextStyle(color: goldClr.withOpacity(0.45), fontSize: 9.sp)),
                      SizedBox(width: 5.w),
                      Text('✦', style: TextStyle(color: goldClr, fontSize: 13.sp)),
                      SizedBox(width: 5.w),
                      Text('✦', style: TextStyle(color: goldClr.withOpacity(0.45), fontSize: 9.sp)),
                    ]),

                    SizedBox(height: 4.h),

                    // Big name — FittedBox so it always fits
                    FittedBox(fit: BoxFit.scaleDown,
                        child: Text(nameData['name']!,
                            style: TextStyle(
                                fontSize: 40.sp, fontFamily: 'Madina',
                                fontWeight: FontWeight.bold, color: nameClr, height: 1.1))),

                    SizedBox(height: 6.h),

                    // Diamond divider
                    Row(children: [
                      Expanded(child: Container(height: 0.8, color: goldClr.withOpacity(0.45))),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: Text('◆', style: TextStyle(color: goldClr, fontSize: 7.sp))),
                      Expanded(child: Container(height: 0.8, color: goldClr.withOpacity(0.45))),
                    ]),

                    SizedBox(height: 6.h),

                    // Meaning — 2 lines max
                    Text(nameData['meaning']!,
                        style: AppTextStyles.madReg11(context, color: textClr.withOpacity(0.82)),
                        textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              )),

          // ── Rafeq hi — overlaps the right edge of the arch ──
          Positioned(
              right: 0, bottom: 0,
              child: Image.asset('assets/images/rafeq_hi.png',
                  height: 180.h, width: 110.w, fit: BoxFit.contain)),
        ]),
      ),
    ]);
  }

  // ====================== Rafeq Circle =========================

  Widget _buildFloatingRafeq(BuildContext context, bool isDark, bool gold) {
    final accentClr = gold
        ? const Color(AppColors.goldPrimary)
        : const Color(AppColors.mainGreen);

    final bubbleBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textClr = isDark ? Colors.white : const Color(0xFF2C2C2C);

    // Pick rafeq image based on recitation state
    final String rafeqImage = 'assets/images/rafeq_floating.png';

    return Positioned(
      left: _rafeqX,
      top: _rafeqY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _rafeqX += details.delta.dx;
            _rafeqY += details.delta.dy;

            // Clamp within screen bounds
            final size = MediaQuery.of(context).size;
            _rafeqX = _rafeqX.clamp(0, size.width - 70.w);
            _rafeqY = _rafeqY.clamp(0, size.height - 70.h);
          });
        },
        onTap: () => setState(() => navigateTo(context, RafeqIntroScreen())),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Speech bubble (shown when expanded) ──
            if (_rafeqExpanded)
              Container(
                width: 180.w,
                margin: EdgeInsets.only(bottom: 6.h, left: 10.w),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: bubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14.r),
                    topRight: Radius.circular(14.r),
                    bottomRight: Radius.circular(14.r),
                    bottomLeft: Radius.circular(4.r),
                  ),
                  border: Border.all(
                    color: accentClr.withOpacity(0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text('تبقى لك  صفحة في وردك 📖',
                  style: AppTextStyles.madReg12(context, color: textClr),
                  textAlign: TextAlign.right,
                ),
              ),

            // ── Rafeq circle ──
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentClr.withOpacity(0.15),
                // border: Border.all(color: accentClr, width: 2),
                image: DecorationImage(image: AssetImage(rafeqImage)),
                boxShadow: [
                  BoxShadow(
                    color: accentClr.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              // child: Image.asset(
              //   rafeqImage,
              //   fit: BoxFit.cover,
              //   alignment: Alignment.topCenter,
              // ),
            ),
          ],
        ),
      ),
    );
  }


  // ====================== random ayah and hadith ======================
  Widget _buildDailyAyahSection(
      BuildContext context,
      HomeCubit cubit,
      bool isDark,
      bool gold,
      ) {
    final ayah = cubit.currentDailyAyah;

    final accentClr = gold
        ? const Color(AppColors.goldPrimary)
        : const Color(AppColors.mainGreen);

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(
      isDark
          ? AppColors.containerDarkBorders
          : AppColors.containerLightBorders,
    );

    final textClr = gold
        ? const Color(AppColors.goldText)
        : isDark
        ? Colors.white
        : Colors.black;

    if (ayah == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderClr),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accentClr.withOpacity(0.10),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/rafeq_reading.png',
            width: 82.w,
            height: 82.w,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: accentClr, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text(
                      'آية اليوم',
                      style: AppTextStyles.madB14(context, color: textClr),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: cubit.refreshDailyAyah,
                      child: Icon(
                        Icons.refresh_rounded,
                        color: accentClr,
                        size: 18.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  ayah['text'] ?? '',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.arsura17(context, color: textClr),
                ),
                SizedBox(height: 8.h),
                Text(
                  'سورة ${ayah['surahName']} - آية ${ayah['verseNumber']}',
                  style: AppTextStyles.madReg12(
                    context,
                    color: accentClr,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyHadithSection(
      BuildContext context,
      HomeCubit cubit,
      bool isDark,
      bool gold,
      ) {
    final hadith = cubit.currentDailyHadith;

    final accentClr = gold
        ? const Color(AppColors.goldPrimary)
        : const Color(AppColors.mainGreen);

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(
      isDark
          ? AppColors.containerDarkBorders
          : AppColors.containerLightBorders,
    );

    final textClr = gold
        ? const Color(AppColors.goldText)
        : isDark
        ? Colors.white
        : Colors.black;

    if (hadith == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderClr),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/rafeq_pray.png',
            width: 78.w,
            height: 78.w,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, color: accentClr, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text(
                      'حديث اليوم',
                      style: AppTextStyles.madB14(context, color: textClr),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: cubit.refreshDailyHadith,
                      child: Icon(
                        Icons.refresh_rounded,
                        color: accentClr,
                        size: 18.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  hadith['hadith'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.madReg14(context, color: textClr),
                ),
                SizedBox(height: 8.h),
                Text(
                  hadith['source'] ?? '',
                  style: AppTextStyles.madReg12(
                    context,
                    color: accentClr,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================== UI ======================

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeState) {
        final isDark = ThemeCubit.get(context).isDark;

        final borderClr = AppColors.isGoldMode
            ? const Color(AppColors.goldBorder)
            : Color(isDark
            ? AppColors.containerDarkBorders
            : AppColors.containerLightBorders);

        final textClr = AppColors.isGoldMode
            ? const Color(AppColors.goldText)
            : (isDark ? Colors.white : Colors.black);

        final iconClr = AppColors.isGoldMode
            ? const Color(AppColors.goldPrimary)
            : const Color(AppColors.mainGreen);

        final gold = AppColors.isGoldMode;

        return BlocListener<HomeCubit, HomeStates>(
          listenWhen: (prev, curr) => curr is HomeTutorialStepRequested,
          listener: (context, state) async {
            if (state is HomeTutorialStepRequested) {
              final cubit = HomeCubit.get(context);

              final canShow = cubit.markStepAsShowing(state.index);
              if (!canShow) return;

              if (!mounted) return;

              await Future.delayed(const Duration(milliseconds: 150));
              if (!mounted) return;

              await _showCoach(context, cubit, isDark);
            }
          },
          child: BlocBuilder<HomeCubit, HomeStates>(
            builder: (context, state) {
              final cubit = HomeCubit.get(context);

              return Stack(
                alignment: AlignmentGeometry.center,
                children: [

                  Scaffold(
                    body: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/mostakeem_logo.png",
                              width: 250.w,
                            ),
                            SizedBox(height: 25.h),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: cubit.homeScrollController,
                                child: Column(
                                  children: [
                                    // Prayer container
                                    BlocBuilder<PrayerTimesCubit, PrayerTimesStates>(
                                      builder: (context, state) {
                                        final c =
                                        PrayerTimesCubit.get(context);
                                        return AnimatedPrayerContainer(
                                          coachKey: _prayerKey,
                                          isDark: isDark,
                                          prayerName: c.upComingPrayer,
                                          remainingTime: c.remainingTime,
                                          dayName: c.getDayName(),
                                          hijriDate: c.hijriDate,
                                          date: c.date,
                                        );
                                      },
                                    ),

                                    SizedBox(height: 15.h),

                                    // ══ Dynamic Rafeq Carousel ══
                                    BlocBuilder<RecitationCubit,RecitationStates>(
                                      builder: (context,state) {
                                        return BlocBuilder<PrayerTimesCubit, PrayerTimesStates>(
                                          builder: (context, recitationState) {
                                            final recitationCubit = RecitationCubit.get(context);
                                            final prayerCubit     = PrayerTimesCubit.get(context);

                                            return Container(
                                              key: _rafeqCarouselKey,
                                              child: _buildRafeqCarousel(
                                                context,
                                                gold,
                                                recitationCubit,
                                                prayerCubit
                                              ),
                                            );
                                          },
                                        );
                                      }
                                    ),

                                    SizedBox(height: 15.h),


                                    // ── Random Zekr ──
                                    BlocBuilder<HomeCubit, HomeStates>(
                                      buildWhen: (prev, curr) =>
                                      curr is ZekrLoadedState ||
                                          curr is ZekrLoadingState,
                                      builder: (context, zekrState) {
                                        return Container(
                                          key: _zekrKey,
                                          child: _buildZekrSection(
                                            context,
                                            cubit,
                                            isDark,
                                            gold,
                                          ),
                                        );
                                      },
                                    ),

                                    SizedBox(height: 15.h),

                                    // Features Grid
                                    SizedBox(
                                      height: 260.h,                          // ← give the grid more room
                                      child: GridView.builder(
                                        controller: cubit.scrollController,
                                        shrinkWrap: true,
                                        reverse: true,
                                        itemCount: cubit.gridItems.length,
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          mainAxisSpacing: 12.w,             // ← horizontal gap (was 30.h, needlessly large)
                                          crossAxisSpacing: 10.h,            // ← vertical gap (was 20.w — wrong unit for height axis)
                                          childAspectRatio: 0.75,            // ← slightly wider cells
                                        ),
                                        scrollDirection: Axis.horizontal,
                                        itemBuilder: (context, index) {
                                          final item = cubit.gridItems[index];

                                          return InkWell(
                                            key: _gridKeys[index],
                                            onTap: () => cubit.navigateToFeature(context, index, isDark),
                                            borderRadius: BorderRadius.circular(16.r),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,   // ← don't force full cell height
                                              children: [
                                                Container(
                                                  width: 54.h,                  // ← use .h so it respects the row height
                                                  height: 54.h,                 // ← was 65.w (wrong axis, too tall)
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(14.r),
                                                    color: borderClr.withOpacity(.08),
                                                  ),
                                                  padding: EdgeInsets.all(10.h),
                                                  child: Image.asset(
                                                    item["image"]!,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                                SizedBox(height: 6.h),          // ← was 10.h
                                                Text(
                                                  item["title"]!,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTextStyles.madB12(  // ← slightly smaller to fit safely
                                                    context,
                                                    color: textClr,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    SizedBox(height: 15.h),

                                    BlocBuilder<HomeCubit, HomeStates>(
                                      buildWhen: (prev, curr) =>
                                      curr is DailyAyahLoadedState ||
                                          curr is DailyAyahLoadingState,
                                      builder: (context, state) {
                                        return _buildDailyAyahSection(
                                          context,
                                          cubit,
                                          isDark,
                                          gold,
                                        );
                                      },
                                    ),

                                    SizedBox(height: 15.h),

                                    BlocBuilder<HomeCubit, HomeStates>(
                                      buildWhen: (prev, curr) =>
                                      curr is DailyHadithLoadedState ||
                                          curr is DailyHadithLoadingState,
                                      builder: (context, state) {
                                        return _buildDailyHadithSection(
                                          context,
                                          cubit,
                                          isDark,
                                          gold,
                                        );
                                      },
                                    ),
                                    SizedBox(height: 15.h),

                                    // Allah Names
                                    BlocBuilder<HomeCubit, HomeStates>(
                                        buildWhen: (p, c) => c is AllahNameLoadedState || c is AllahNameLoadingState,
                                        builder: (context, _) =>
                                            Container(
                                                key: _allahNameKey,
                                                child: _buildAllahNameSection(context, cubit, isDark, gold))),


                                    SizedBox(height: 20.h),

                                    // Settings
                                    Container(
                                      key: _settingsKey,
                                      child: InkWell(
                                        onTap: () => navigateTo(
                                            context, SettingsScreen()),
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        child: Container(
                                          padding:
                                          EdgeInsetsDirectional.symmetric(
                                            vertical: 10.h,
                                            horizontal: 20.w,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(10),
                                            border:
                                            Border.all(color: borderClr),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              Icon(FontAwesomeIcons.gear,
                                                  color: iconClr),
                                              SizedBox(width: 6.w),
                                              Text(
                                                "الإعدادات",
                                                style: AppTextStyles.madB16(
                                                  context,
                                                  color: textClr,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 20.h),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  BlocBuilder<HomeCubit, HomeStates>(
                    buildWhen: (prev, curr) => curr is RafeqVisibilityChanged,
                    builder: (context, _) {
                      final cubit = HomeCubit.get(context);
                      if (!cubit.showFloatingRafeq) return const SizedBox.shrink();
                      return _buildFloatingRafeq(context, isDark, gold);
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════
// Carousel Slide Data Model
// ══════════════════════════════════════════════════
class _CarouselSlide {
  final String imagePath;
  final String message;
  final bool gold;
  final VoidCallback? onTap;
  final String? badgeText;
  final Color? badgeColor;

  const _CarouselSlide({
    required this.imagePath,
    required this.message,
    required this.gold,
    required this.onTap,
    required this.badgeText,
    required this.badgeColor,
  });
}

// ══════════════════════════════════════════════════
// Coach text widget
// ══════════════════════════════════════════════════
class _CoachContent extends StatelessWidget {
  final String title;
  final String description;
  final Color titleColor;
  final Color descColor;

  const _CoachContent({
    required this.title,
    required this.description,
    required this.titleColor,
    required this.descColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.madB16(context).copyWith(color: titleColor),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style:
            AppTextStyles.madReg12(context).copyWith(color: descColor),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Mosque Arch Panel Painter
// ══════════════════════════════════════════════════
class _ArchPanelPainter extends CustomPainter {
  final Color fill;
  final Color border;
  const _ArchPanelPainter({required this.fill, required this.border});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const double archBaseY = 28.0;
    const double r = 14.0;

    Path _makePath(double w, double h, double archY, double cornerR) {
      final p = Path();
      p.moveTo(cornerR, h);
      p.lineTo(w - cornerR, h);
      p.arcToPoint(Offset(w, h - cornerR), radius: Radius.circular(cornerR));
      p.lineTo(w, archY + 9);
      // Right shoulder → right arch curve → tip
      p.cubicTo(w, archY - 1, w * 0.71, archY - 1, w * 0.61, archY * 0.38);
      p.cubicTo(w * 0.56, archY * 0.08, w * 0.53, 0, w * 0.50, 0);
      // Tip → left arch curve → left shoulder
      p.cubicTo(w * 0.47, 0, w * 0.44, archY * 0.08, w * 0.39, archY * 0.38);
      p.cubicTo(w * 0.29, archY - 1, 0, archY - 1, 0, archY + 9);
      p.lineTo(0, h - cornerR);
      p.arcToPoint(Offset(cornerR, h), radius: Radius.circular(cornerR));
      p.close();
      return p;
    }

    final outerPath = _makePath(w, h, archBaseY, r);

    // Fill
    canvas.drawPath(outerPath, Paint()..color = fill);
    // Outer border
    canvas.drawPath(outerPath, Paint()
      ..color = border ..style = PaintingStyle.stroke ..strokeWidth = 1.5);

    // Inner decorative border
    const ins = 5.5;
    final innerPath = _makePath(w - ins * 2, h - ins * 2, archBaseY - ins * 0.3, r * 0.65);
    final matrix = Matrix4.translationValues(ins, ins, 0);
    canvas.drawPath(innerPath.transform(matrix.storage), Paint()
      ..color = border.withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(covariant _ArchPanelPainter old) =>
      old.fill != fill || old.border != border;
}