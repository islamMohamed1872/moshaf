// podcasts_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/podcast/podcast_states.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';

import '../../controllers/podcast/podcast_cubit.dart';
import '../../models/episode_model.dart';
import '../../services/youtubr_services.dart';
import '../widgets/header.dart';
import 'episode_player_screen.dart';
import 'podcast_episodes_screen.dart';
import 'dart:ui' as ui;

class PodcastsScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeCubit.get(context).isDark;
    final borderClr = AppColors.getBorderColor(isDark: isDark);
    final textClr = AppColors.getTextColor(isDark: isDark);
    final primary = AppColors.getPrimaryColor();
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    final yt = YouTubeService(apiKey: apiKey);
    TextEditingController searchController = TextEditingController();
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: BlocProvider(
            create: (context) => PodcastCubit(yt: yt),
            child: BlocBuilder<PodcastCubit,PodcastStates>(
              builder: (context,state) {
                final cubit = PodcastCubit.get(context);
                return Column(
                  children: [
                    Header(
                      title: "البودكاست",
                      isDark: isDark,
                      iconColor: textClr,
                    ),
                    SizedBox(height: 10.h),
                    Container(
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
                            onChanged: (value) => cubit.search(value),
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
                    SizedBox(height: 10.h),
                    Expanded(
                      child: ListView.separated(
                        itemCount: searchController.text.isEmpty?cubit.originalList.length:cubit.filteredList.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
            
                          final p = searchController.text.isEmpty?cubit.originalList[index]:cubit.filteredList[index];
            
                          return InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () {
                              if(p['type'] == "playlist") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider(
                                      create:(context) =>  PodcastCubit(yt: yt),
                                      child: PodcastEpisodesScreen(
                                        title: p['title']!,
                                        playlistIdOrUrl: p['playlist']!,
                                        coverImage: p['image'],
                                        primaryColor: primary,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              else{
                                final videoId = p['id']!;
            
                                // Build episode model manually (you have to)
                                final episode = Episode(
                                  videoId: videoId,
                                  title: p['title']!,
                                  description: "",
                                  durationIso: "",
                                  durationReadable: "",
                                  thumbnail: p['image'],
                                  viewCount: null,
                                  publishedAt: null,
                                );
            
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PodcastPlayerScreen(episode: episode),
                                  ),
                                );
                              }
                            },
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 1.0, end: 1.0),
                              duration: Duration(milliseconds: 180),
                              builder: (context, scale, child) => Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                padding: EdgeInsets.all(18.w),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: isDark
                                      ? LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.06),
                                      Colors.white.withOpacity(0.03),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                      : LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.grey.shade50,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: primary.withOpacity(0.25),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withOpacity(0.10),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                      offset: Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Thumbnail with hero animation + glow
                                    Hero(
                                      tag: p['playlist']??p['id']!,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primary.withOpacity(0.35),
                                              blurRadius: 14,
                                              spreadRadius: 1,
                                            )
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: Image.network(
                                            p['image']!,
                                            width: 110.w,
                                            height: 90.w,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
            
                                    SizedBox(width: 16.w),
            
                                    // Title
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['title']!,
                                            style: AppTextStyles.madB16(context, color: textClr).copyWith(
                                              fontSize: 19.sp,
                                              height: 1.35,
                                            ),
                                          ),
            
                                          SizedBox(height: 6.h),
            
                                          // subtle subtitle hint
                                          Text(
                                            p['type']=="playlist"?"مشاهدة جميع الحلقات":"مشاهدة الحلقة",
                                            style: AppTextStyles.madReg12(context, color: textClr.withOpacity(0.6)),
                                          ),
                                        ],
                                      ),
                                    ),
            
                                    SizedBox(width: 10.w),
            
                                    // Icon
                                    Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        context.locale.languageCode=="ar"?
                                        Icons.arrow_forward_ios:
                                        Icons.arrow_back_ios_new_rounded,
                                        color: primary,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ),
      ),
    );
  }
}
