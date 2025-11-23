// podcast_episodes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../controllers/podcast/podcast_cubit.dart';
import '../../controllers/podcast/podcast_states.dart';
import '../../models/episode_model.dart';
import '../widgets/header.dart';
import 'episode_player_screen.dart';
import 'dart:ui' as ui;

class PodcastEpisodesScreen extends StatefulWidget {
  final String title;
  final String playlistIdOrUrl;
  final String? coverImage;
  final Color primaryColor;

  PodcastEpisodesScreen({
    required this.title,
    required this.playlistIdOrUrl,
    this.coverImage,
    required this.primaryColor,
  });

  @override
  State<PodcastEpisodesScreen> createState() => _PodcastEpisodesScreenState();
}

class _PodcastEpisodesScreenState extends State<PodcastEpisodesScreen> {
  @override
  void initState() {
    super.initState();
    // fetch playlist
    final cubit = context.read<PodcastCubit>();
    cubit.fetchPlaylist(widget.playlistIdOrUrl);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeCubit.get(context).isDark;
    final borderClr = AppColors.getBorderColor(isDark: isDark);
    final textClr = AppColors.getTextColor(isDark: isDark);
    TextEditingController searchController = TextEditingController();
    return BlocBuilder<PodcastCubit,PodcastStates>(
      builder: (context,state) {
        final cubit = PodcastCubit.get(context);
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Header(
                  title: widget.title,
                  isDark: isDark,
                  iconColor: textClr,
                ),
                if (widget.coverImage != null)
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(widget.coverImage!, height: 170.h, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 15.0),
                  child: Container(
                    width: double.infinity,
                    height: 48.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: AppColors.isGoldMode
                          ? const Color(AppColors.goldBackground)
                          : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                      border: Border.all(
                        color: AppColors.isGoldMode
                            ? const Color(AppColors.goldBorder)
                            : borderClr.withOpacity(0.70),
                        width: AppColors.isGoldMode ? 1.4 : 1.0,
                      ),
                      boxShadow: [
                        if (!AppColors.isGoldMode)
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.25)
                                : Colors.grey.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        if (AppColors.isGoldMode)
                          BoxShadow(
                            color: const Color(AppColors.goldPrimary).withOpacity(0.25),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: TextFormField(
                          controller: searchController,
                          onChanged: (value) => cubit.searchEpisode(value),
                          cursorColor:
                          AppColors.isGoldMode ? const Color(AppColors.goldPrimary) : textClr.withOpacity(0.9),
                          style: TextStyle(
                            color: AppColors.isGoldMode
                                ? const Color(AppColors.goldPrimary)
                                : textClr.withOpacity(0.85),
                            fontSize: 15.sp,
                          ),
                          decoration: InputDecoration(
                            icon: Icon(
                              Icons.search,
                              color: AppColors.isGoldMode
                                  ? const Color(AppColors.goldPrimary)
                                  : textClr.withOpacity(0.75),
                              size: 22,
                            ),
                            hintText: "بحث",
                            hintStyle: TextStyle(
                              color: AppColors.isGoldMode
                                  ? const Color(AppColors.goldPrimary).withOpacity(0.55)
                                  : textClr.withOpacity(0.55),
                              fontSize: 14.sp,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.all(16.w),
                    itemCount: searchController.text.isEmpty? cubit.episodes.length:cubit.filteredEpisodes.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final ep =  searchController.text.isEmpty?cubit.episodes[index]:cubit.filteredEpisodes[index];
                      return InkWell(
                        onTap: () {
                          navigateTo(context, PodcastPlayerScreen(episode: ep));
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderClr),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ep.thumbnail != null
                                    ? Image.network(ep.thumbnail!, width: 90.w, height: 70.w, fit: BoxFit.cover)
                                    : Container(width: 90.w, height: 70.w),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ep.title, style: AppTextStyles.madB16(context, color: textClr)),
                                    SizedBox(height: 6.h),
                                    Text(ep.description, style: AppTextStyles.madReg12(context, color: textClr), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    Text(ep.durationReadable, style: AppTextStyles.madReg12(context, color: textClr)),
                                    SizedBox(height: 6.h),
                                    if (ep.viewCount != null) Text('${ep.viewCount} مشاهدة', style: AppTextStyles.madReg10(context, color: textClr)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                )
              ],
            ),
          ),
        );
      }
    );
  }
}
