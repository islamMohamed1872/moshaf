import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/daily_challenge/daily_challenge_cubit.dart';
import '../../models/daily_challenge.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../widgets/header.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  int? selectedIndex;
  bool answered = false;
  int? correctIndex;

  @override
  void initState() {
    super.initState();
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
              iconColor: gold
                  ? const Color(AppColors.goldText)
                  : (isDark ? Colors.white : Colors.black),
            ),
            20.h.verticalSpace,

            Expanded(
              child: BlocConsumer<DailyChallengeCubit, DailyChallengeState>(
                listener: (context, state) {
                  if (state is DailyChallengeSubmitted) {
                    final msg = state.isCorrect ? "✓ إجابة صحيحة! +10 نقاط" : "✗ إجابة خاطئة";

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("$msg — الوقت: ${state.responseMs}ms"),
                        backgroundColor: state.isCorrect
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                      ),
                    );
                  }

                  if (state is DailyChallengeLoaded) {
                    final cubit = DailyChallengeCubit.get(context);

                    selectedIndex = cubit.savedAnswer; // restore answer
                    answered = cubit.savedAnswer != null;
                    correctIndex = cubit.dailyChallenge!.correctIndex;

                    setState(() {}); // refresh UI
                  }
                },

                builder: (context, state) {
                  final cubit = DailyChallengeCubit.get(context);

                  if (state is DailyChallengeLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is DailyChallengeEmpty) {
                    final textClr = gold
                        ? const Color(AppColors.goldText)
                        : (isDark ? Colors.white : Colors.black);

                    return Center(
                      child: Text(
                        "لا يوجد تحدي اليوم",
                        style: AppTextStyles.madB16(context, color: textClr),
                      ),
                    );
                  }

                  return _buildQuestion(context, cubit.dailyChallenge!);
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
            "سؤال اليوم: ${c.id}",
            style: AppTextStyles.madReg12(context, color: textClr.withOpacity(0.6)),
          ),

          10.h.verticalSpace,

          Text(
            c.question,
            style: AppTextStyles.madB18(context, color: textClr),
          ),

          20.h.verticalSpace,

          ...List.generate(c.options.length, (index) {
            Color bg = gold?Color(AppColors.goldAccent): isDark ? const Color(0xff232634) : const Color(0xffF5F5F5);
            Color borderColor = Colors.transparent;
            Color textColor = textClr;
            double borderWidth = 1.5;

            if (answered) {
              if (index == selectedIndex && index != correctIndex) {
                bg = Colors.red.withOpacity(0.2);
                borderColor = Colors.red;
                borderWidth = 2.5;
                textColor = Colors.red.shade700;
              } else if (index == correctIndex) {
                bg = Colors.green.withOpacity(0.2);
                borderColor = Colors.green;
                borderWidth = 2.5;
                textColor = Colors.green.shade700;
              } else {
                bg = bg.withOpacity(0.5);
                textColor = textClr.withOpacity(0.4);
              }
            }

            return GestureDetector(
              onTap: answered
                  ? null
                  : () async {
                if (!mounted) return;

                setState(() => selectedIndex = index);

                cubit.startTimer();
                await cubit.submitAnswer(
                  uid: uid,
                  challenge: c,
                  selectedIndex: index,
                );

                if (!mounted) return;

                setState(() => answered = true);
              },
              child: AnimatedContainer(
                width: double.infinity,
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(vertical: 8.h),
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
                child: Text(
                  c.options[index],
                  style: AppTextStyles.madReg14(context, color: textColor),
                ),
              ),
            );
          }),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                );
              },
              child: Text(
                "عرض لوحة المتصدرين",
                style: AppTextStyles.madB14(context, color: Colors.white),
              ),
            ),
          ),

          20.h.verticalSpace,
        ],
      ),
    );
  }
}
