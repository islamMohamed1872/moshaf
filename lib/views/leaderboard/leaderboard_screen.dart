import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';

import '../../controllers/leaderboard/leaderboard_cubit.dart';
import '../../models/daily_challenge.dart';
import '../../models/leaderboard_row.dart';
import '../../services/firestore_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../widgets/header.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  LeaderboardSortBy sortBy = LeaderboardSortBy.totalCorrect;

  @override
  void initState() {
    super.initState();
    context.read<LeaderboardCubit>().load(limit: 100, sortBy: sortBy);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context,state) {
            final isDark = context.watch<ThemeCubit>().isDark;
            print(isDark);
            final textClr = AppColors.isGoldMode
                ? const Color(AppColors.goldText)
                : (isDark ? Colors.white : Colors.black);
            return Column(
              children: [
                Header(
                  title: "لوحة المتصدرين",
                  isDark: isDark,
                  iconColor: AppColors.isGoldMode
                      ? const Color(AppColors.goldText)
                      : (isDark ? Colors.white : Colors.black),
                ),
                SizedBox(height: 20.h),
                // _buildFilters(isDark),
                // SizedBox(height: 15.h),
                Expanded(
                  child: BlocBuilder<LeaderboardCubit, LeaderboardState>(
                    builder: (context, state) {
                      if (state is LeaderboardLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (state is LeaderboardLoaded) {
                        return _leaderboardView(state.rows,isDark);
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }



  // ================================================================
  // 🔹 FILTERS
  // ================================================================
  Widget _buildFilters(bool isDark) {

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _filterChip("عام", sortBy == LeaderboardSortBy.totalCorrect, () {
            _changeSort(LeaderboardSortBy.totalCorrect);
          },isDark),
          SizedBox(width: 10.w),
          _filterChip("الأسرع", sortBy == LeaderboardSortBy.fastestAnswer, () {
            _changeSort(LeaderboardSortBy.fastestAnswer);
          },isDark),
          SizedBox(width: 10.w),
          _filterChip("سلسلة", sortBy == LeaderboardSortBy.longestStreak, () {
            _changeSort(LeaderboardSortBy.longestStreak);
          },isDark),
        ],
      ),
    );
  }

  void _changeSort(LeaderboardSortBy sort) {
    setState(() => sortBy = sort);
    context.read<LeaderboardCubit>().load(limit: 100, sortBy: sort);
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap,bool isDark) {
    final textClr = AppColors.isGoldMode
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected
              ? const Color(AppColors.goldPrimary)
              : textClr.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected
                ? const Color(AppColors.goldPrimary)
                : textClr.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.madB12(
            context,
            color: selected ? Colors.white :textClr,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // 🔹 MAIN VIEW
  // ================================================================
  Widget _leaderboardView(List<UserStats> rows,bool isDark) {
    final top3 = _normalizeTop3(rows);
    final List<UserStats> rest = rows.length > 3 ? rows.skip(3).toList() : [];

    return Column(
      children: [
        _topThreePodium(top3,isDark),
        SizedBox(height: 15.h),
        Expanded(
          child: _rankedList(
            rest,
            startFromTop: rows.length < 3,
          ),
        ),
      ],
    );
  }

  List<UserStats?> _normalizeTop3(List<UserStats> rows) {
    return [
      rows.isNotEmpty ? rows[0] : null,
      rows.length > 1 ? rows[1] : null,
      rows.length > 2 ? rows[2] : null,
    ];
  }

  // ================================================================
  // 🔹 PODIUM - ENHANCED
  // ================================================================
  Widget _topThreePodium(List<UserStats?> rows,bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SizedBox(
        height: 280.h,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // ✅ ENHANCED PODIUM BLOCKS WITH GRADIENT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd Place
                _podiumBlock(
                  position: 3,
                  height: 80.h,
                  color: Colors.amber[600]!,
                ),
                SizedBox(width: 12.w),
                // 1st Place
                _podiumBlock(
                  position: 1,
                  height: 140.h,
                  color: Colors.yellow[600]!,
                ),
                SizedBox(width: 12.w),
                // 3rd Place
                _podiumBlock(
                  position: 2,
                  height: 100.h,
                  color: Colors.orange[600]!,
                ),
              ],
            ),

            // ✅ AVATARS WITH MEDALS
            Positioned(
              bottom: 130.h,
              left: 0,
              child: _podiumAvatarWithMedal(rows[1], "🥈",isDark),
            ),
            Positioned(
              bottom: 165.h,
              child: _podiumAvatarWithMedal(rows[0], "🥇",isDark),
            ),
            Positioned(
              bottom: 110.h,
              right: 0,
              child: _podiumAvatarWithMedal(rows[2], "🥉",isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _podiumBlock({
    required int position,
    required double height,
    required Color color,
  }) {

    return Container(
      width: 70.w,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.r),
        ),
        border: Border.all(
          color: color.withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          )
        ],
      ),
      child: Center(
        child: Text(
          "#$position",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(2, 2),
                blurRadius: 4,
              )
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ AVATAR WITH MEDAL EMOJI
  Widget _podiumAvatarWithMedal(UserStats? user, String medal,bool isDark) {
    final textClr = AppColors.isGoldMode
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);
    final iconColor = AppColors.isGoldMode?
        const Color(AppColors.goldAccent):
        Colors.grey;
    return SizedBox(
      width: 80.w,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 32.r,
                backgroundColor: textClr,
                backgroundImage: user != null && user.photoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(user.photoUrl)
                    : null,
                child: user == null || user.photoUrl.isEmpty
                    ? Icon(
                  Icons.person,
                  size: 32.w,
                  color: iconColor,
                )
                    : null,
              ),
              // ✅ MEDAL BADGE
              Positioned(
                bottom: -8.h,
                right: -8.w,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xff1B1D2A),
                    border: Border.all(
                      color: Colors.amber,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    medal,
                    style: TextStyle(fontSize: 20.sp),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (user != null)
            Column(
              children: [
                Text(
                  user.displayName.length > 8
                      ? user.displayName.substring(0, 8)
                      : user.displayName,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.madB12(context, color: textClr),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  "⭐ ${user.totalPoints}",
                  style: AppTextStyles.madReg12(
                    context,
                    color: textClr,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Text(
                  "—",
                  style: AppTextStyles.madB12(context, color: Colors.white38),
                ),
                SizedBox(height: 4.h),
                Text(
                  "0 نقاط",
                  style: AppTextStyles.madReg12(context, color: Colors.white24),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ================================================================
  // 🔹 RANKED LIST - ENHANCED
  // ================================================================
  Widget _rankedList(List<UserStats> users, {bool startFromTop = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xff232634),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          )
        ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        itemCount: users.length,
        separatorBuilder: (_, __) => Divider(
          color: Colors.white.withOpacity(0.08),
          thickness: 1,
          height: 12.h,
        ),
        itemBuilder: (context, i) {
          final rank = startFromTop ? (i + 1) : (i + 4);
          final u = users[i];

          // ✅ RANK COLOR BASED ON POSITION
          Color rankColor = Colors.white70;
          if (rank <= 10) rankColor = Colors.amber;
          if (rank <= 5) rankColor = Colors.amber.shade300;

          return Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                // ✅ RANK WITH TROPHY
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rankColor.withOpacity(0.15),
                    border: Border.all(
                      color: rankColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "#$rank",
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // ✅ AVATAR
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: Colors.white24,
                  backgroundImage: u.photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(u.photoUrl)
                      : null,
                  child: u.photoUrl.isEmpty
                      ? Text(
                    u.displayName.isNotEmpty
                        ? u.displayName[0].toUpperCase()
                        : "?",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                SizedBox(width: 14.w),

                // ✅ USER INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.displayName,
                        style: AppTextStyles.madB14(context, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14.w,
                            color: Colors.green.shade400,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            "${u.totalCorrectAnswers} صحيح",
                            style: AppTextStyles.madReg12(
                              context,
                              color: Colors.white70,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Icon(
                            Icons.star,
                            size: 14.w,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            "${u.totalPoints} نقطة",
                            style: AppTextStyles.madReg12(
                              context,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}