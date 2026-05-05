import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/daily_challenge/daily_challenge_cubit.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../../models/daily_challenge.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../widgets/header.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with TickerProviderStateMixin {
  int? selectedIndex;
  bool answered = false;
  int? correctIndex;

  // 🔥 Animations
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_fade);

    context.read<DailyChallengeCubit>().loadToday();
    _ensureSignedIn();
  }

  Future<void> _ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().isDark;
    final gold = AppColors.isGoldMode;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(
              title: "تحدي اليوم",
              isDark: isDark,
              textColor: isDark?Colors.white:Colors.black,
              iconColor: gold
                  ? const Color(AppColors.goldText)
                  : (isDark ? Colors.white : Colors.black),
            ),
            20.h.verticalSpace,

            Expanded(
              child: BlocConsumer<DailyChallengeCubit, DailyChallengeState>(
                listener: (context, state) {
                  if (state is DailyChallengeLoaded) {
                    final cubit = DailyChallengeCubit.get(context);
                    selectedIndex = cubit.savedAnswer;
                    answered = cubit.savedAnswer != null;
                    correctIndex = cubit.dailyChallenge!.correctIndex;
                    _controller.forward(from: 0);
                  }
                },
                builder: (context, state) {
                  final cubit = DailyChallengeCubit.get(context);

                  if (state is DailyChallengeLoading) {
                    return  Center(child: CircularProgressIndicator(
                      color: gold
                          ? const Color(AppColors.goldText)
                          : (isDark ? Colors.white : Colors.black),
                    ));
                  }

                  if (state is DailyChallengeEmpty) {
                    return Center(
                      child: Text(
                        "لا يوجد تحدي اليوم",
                        style: AppTextStyles.madB16(
                          context,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }

                  if (state is DailyChallengeLoaded) {
                    selectedIndex = cubit.savedAnswer;
                    answered = cubit.savedAnswer != null;
                    correctIndex = cubit.dailyChallenge!.correctIndex;

                    _controller.forward(from: 0);

                    return FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: _buildQuestion(context, cubit.dailyChallenge!),
                      ),
                    );
                  }
                  if (state is DailyChallengeLoaded ||
                      state is DailyChallengeSubmitting ||
                      state is DailyChallengeSubmitted) {
                    selectedIndex = cubit.savedAnswer;
                    answered = cubit.savedAnswer != null;
                    correctIndex = cubit.dailyChallenge!.correctIndex;

                    _controller.forward(from: 0);

                    return FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: _buildQuestion(context, cubit.dailyChallenge!),
                      ),
                    );
                  }

                  return const SizedBox();
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, DailyChallenge c) {
    final cubit = DailyChallengeCubit.get(context);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final isDark = context.watch<ThemeCubit>().isDark;
    final gold = AppColors.isGoldMode;

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "سؤال اليوم",
            style: AppTextStyles.madReg12(
              context,
              color: textClr.withOpacity(0.6),
            ),
          ),

          10.h.verticalSpace,

          Text(
            c.question,
            style: AppTextStyles.madB18(context, color: textClr),
          ),

          20.h.verticalSpace,

          // 🔥 OPTIONS
          ...List.generate(c.options.length, (index) {
            Color bg = gold
                ? const Color(AppColors.goldAccent)
                : isDark
                ? const Color(0xff232634)
                : const Color(0xffF5F5F5);

            Color borderColor = Colors.transparent;
            Color textColor = textClr;
            double borderWidth = 1.5;

            if (answered) {
              if (index == selectedIndex && index != correctIndex) {
                bg = Colors.red.withOpacity(0.15);
                borderColor = Colors.red;
                textColor = Colors.red.shade700;
                borderWidth = 2.5;
              } else if (index == correctIndex) {
                bg = Colors.green.withOpacity(0.15);
                borderColor = Colors.green;
                textColor = Colors.green.shade700;
                borderWidth = 2.5;
              } else {
                textColor = textClr.withOpacity(0.4);
              }
            }

            return GestureDetector(
              onTap: answered
                  ? null
                  : () async {
                setState(() => selectedIndex = index);
                cubit.startTimer();
                await cubit.submitAnswer(
                  uid: uid,
                  challenge: c,
                  selectedIndex: index,
                );
                setState(() => answered = true);
              },
              child: AnimatedScale(
                scale: answered && index == correctIndex ? 1.05 : 1,
                duration: const Duration(milliseconds: 250),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(vertical: 8.h),
                  padding: EdgeInsets.symmetric(
                    vertical: 16.h,
                    horizontal: 16.w,
                  ),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                  ),
                  child: Text(
                    c.options[index],
                    style: AppTextStyles.madReg14(
                      context,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            );
          }),

          const Spacer(),

          // 🔥 RESULT CARD
          if (answered)
            Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: selectedIndex == correctIndex
                    ? Colors.green.withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedIndex == correctIndex
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedIndex == correctIndex
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: selectedIndex == correctIndex
                        ? Colors.green
                        : Colors.red,
                  ),
                  10.w.horizontalSpace,
                  Expanded(
                    child: Text(
                      selectedIndex == correctIndex
                          ? "إجابة صحيحة 🎉 +10 نقاط"
                          : "إجابة خاطئة ❌ حاول غداً",
                      style:
                      AppTextStyles.madB14(context, color: textClr),
                    ),
                  ),
                ],
              ),
            ),

          // 🔥 LEADERBOARD BUTTON
          IgnorePointer(
            ignoring: !answered,
            child: AnimatedOpacity(
              opacity: answered ? 1 : 0.4,
              duration: const Duration(milliseconds: 300),
              child: SizedBox(
                width: double.infinity,
                child: Focus(
                  canRequestFocus: false,
                  descendantsAreFocusable: false,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold
                          ? const Color(AppColors.goldPrimary)
                          : Color(AppColors.mainGreen),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LeaderboardScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "عرض لوحة المتصدرين",
                      style: AppTextStyles.madB14(
                        context,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          20.h.verticalSpace,
        ],
      ),
    );
  }
}