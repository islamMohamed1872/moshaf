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
import 'package:moshaf/views/settings/settings_screen.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../controllers/theme/theme_cubit.dart';
import '../widgets/custom_green_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GlobalKey _prayerKey;
  late final GlobalKey _settingsKey;
  late final List<GlobalKey> _gridKeys;

  @override
  void initState() {
    super.initState();

    _prayerKey = GlobalKey();
    _settingsKey = GlobalKey();

    final cubit = HomeCubit.get(context);
    _gridKeys = List.generate(cubit.gridItems.length, (_) => GlobalKey());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = HomeCubit.get(context);
      await cubit.getFirstTime();

      if (cubit.isFirstTime == true) {
        cubit.startTutorial();
      }
    });
  }

  @override
  void dispose() {
    HomeCubit.get(context).closeCoach();
    super.dispose();
  }

  // ====================== Tutorial Helpers ======================

  TargetFocus _buildTargetForIndex(
      BuildContext context,
      bool isDark,
      HomeCubit cubit,
      ) {
    final gold = AppColors.isGoldMode;
    final titleClr = gold ? const Color(AppColors.goldAccent) : Colors.white;
    final descClr = Colors.white.withOpacity(0.9);

    final gridCount = cubit.gridItems.length;

    if (cubit.tutorialIndex == 0) {
      return TargetFocus(
        identify: "prayer",
        keyTarget: _prayerKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _CoachContent(
              title: cubit.coachContent[cubit.tutorialIndex]['title'],
              description: cubit.coachContent[cubit.tutorialIndex]['content'],
              titleColor: titleClr,
              descColor: descClr,
            ),
          ),
        ],
      );
    }

    if (cubit.tutorialIndex >= 1 && cubit.tutorialIndex <= gridCount) {
      final index = cubit.tutorialIndex - 1;
      final item = cubit.gridItems[index];

      return TargetFocus(
        identify: "grid_$index",
        keyTarget: _gridKeys[index],
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _CoachContent(
              title: cubit.coachContent[cubit.tutorialIndex]['title'],
              description: cubit.coachContent[cubit.tutorialIndex]['content'],
              titleColor: titleClr,
              descColor: descClr,
            ),
          ),
        ],
      );
    }

    return TargetFocus(
      identify: "settings",
      keyTarget: _settingsKey,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          child: _CoachContent(
            title: "الإعدادات",
            description: "من هنا يمكنك تغيير الإعدادات والثيم واللغة.",
            titleColor: titleClr,
            descColor: descClr,
          ),
        ),
      ],
    );
  }

  Future<void> _scrollToStep(HomeCubit cubit) async {
    final gridCount = cubit.gridItems.length;

    BuildContext? ctx;

    if (cubit.tutorialIndex == 0) {
      ctx = _prayerKey.currentContext;
    } else if (cubit.tutorialIndex >= 1 && cubit.tutorialIndex <= gridCount) {
      ctx = _gridKeys[cubit.tutorialIndex - 1].currentContext;
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
  Future<void> _showCoach(BuildContext context, HomeCubit cubit, bool isDark) async {
    await _scrollToStep(cubit);

    final target = _buildTargetForIndex(context, isDark, cubit);
    final lastIndex = cubit.gridItems.length + 1;

    cubit.activeCoach = TutorialCoachMark(
      targets: [target],
      colorShadow: Colors.black.withOpacity(0.85),
      textSkip: "تخطي",
      paddingFocus: 12,
      opacityShadow: 0.8,

      /// ✅ DO NOT close coach here
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
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
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
                style: AppTextStyles.madB20(context).copyWith(color: Colors.white),
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

        return BlocListener<HomeCubit, HomeStates>(
          listenWhen: (prev, curr) => curr is HomeTutorialStepRequested,
          listener: (context, state) async {
            if (state is HomeTutorialStepRequested) {
              final cubit = HomeCubit.get(context);

              // ✅ prevent duplicates
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

              return Scaffold(
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
                                    final c = PrayerTimesCubit.get(context);
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

                                // Grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: cubit.gridItems.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 15.h,
                                    crossAxisSpacing: 15.w,
                                    childAspectRatio: 1.3,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = cubit.gridItems[index];

                                    return Container(
                                      key: _gridKeys[index], // ✅ key must be on container
                                      child: InkWell(
                                        onTap: () =>
                                            cubit.navigateToFeature(context, index, isDark),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: EdgeInsetsDirectional.symmetric(
                                            vertical: 10.h,
                                            horizontal: 20.w,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: borderClr),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Image.asset(
                                                  item["image"]!,
                                                  width: 50.w,
                                                  height: 50.w,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                item["title"]!,
                                                textAlign: TextAlign.center,
                                                style: AppTextStyles.madB16(
                                                  context,
                                                  color: textClr,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                SizedBox(height: 20.h),

                                // Settings
                                Container(
                                  key: _settingsKey,
                                  child: InkWell(
                                    onTap: () => navigateTo(context, SettingsScreen()),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: EdgeInsetsDirectional.symmetric(
                                        vertical: 10.h,
                                        horizontal: 20.w,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: borderClr),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(FontAwesomeIcons.gear, color: iconClr),
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
              );
            },
          ),
        );
      },
    );
  }
}

// Coach text widget
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
            style: AppTextStyles.madReg12(context).copyWith(color: descColor),
          ),
        ],
      ),
    );
  }
}
