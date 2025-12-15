import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';

import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/podcast/podcast_cubit.dart';
import 'package:moshaf/controllers/podcast/podcast_states.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';
import 'package:moshaf/models/episode_model.dart';
import 'package:moshaf/services/youtube_services.dart';
import 'package:moshaf/views/widgets/header.dart';

import 'episode_player_screen.dart';
import 'podcast_episodes_screen.dart';


class PodcastsScreen extends StatelessWidget {
  const PodcastsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeCubit.get(context).isDark;
    final borderClr = AppColors.getBorderColor(isDark: isDark);
    final textClr = AppColors.getTextColor(isDark: isDark);
    final primary = AppColors.getPrimaryColor();

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    final yt = YouTubeService(apiKey: apiKey);

    final searchController = TextEditingController();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: BlocProvider(
            create: (_) => PodcastCubit(yt: yt),
            child: BlocBuilder<PodcastCubit, PodcastStates>(
              builder: (context, state) {
                final cubit = PodcastCubit.get(context);

                /// -----------------------------
                /// Visible list (search + category)
                /// -----------------------------
                final List<Map<String, String>> visibleList =
                cubit.getVisibleList();

                return Column(
                  children: [
                    /// -----------------------------
                    /// Header
                    /// -----------------------------
                    Header(
                      title: "مقاطع الفيديو",
                      isDark: isDark,
                      iconColor: textClr,
                    ),

                    SizedBox(height: 12.h),

                    /// -----------------------------
                    /// Search Field
                    /// -----------------------------
                    Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: AppColors.isGoldMode
                            ? const Color(AppColors.goldBackground)
                            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                        border: Border.all(
                          color: AppColors.isGoldMode
                              ? const Color(AppColors.goldBorder)
                              : borderClr.withOpacity(0.7),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: TextFormField(
                          controller: searchController,
                          onChanged: cubit.search,
                          cursorColor: primary,
                          style: TextStyle(
                            color: textClr,
                            fontSize: 15.sp,
                          ),
                          decoration: InputDecoration(
                            icon: Icon(Icons.search, color: primary),
                            hintText: "بحث",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    /// -----------------------------
                    /// Category Chips
                    /// -----------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: PodcastCategory.values.map((cat) {
                        final bool isSelected = cubit.selectedCategory == cat;

                        String label;
                        switch (cat) {
                          case PodcastCategory.all:
                            label = "الكل";
                            break;
                          case PodcastCategory.deen:
                            label = "دِين";
                            break;
                          case PodcastCategory.dunya:
                            label = "دُنْيَا";
                            break;
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          child: ChoiceChip(
                            label: Text(
                              label,
                              style: AppTextStyles.madReg14(
                                context,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.getTextColor(isDark: isDark),
                              ),
                            ),

                            selected: isSelected,

                            // ✅ Selected background
                            selectedColor: AppColors.getPrimaryColor(),

                            // ✅ Unselected background
                            backgroundColor: AppColors.isGoldMode
                                ? const Color(AppColors.goldBackground)
                                : isDark
                                ? Colors.black.withValues(alpha: 0.7)
                                : Colors.grey.shade200,

                            // ✅ Border for better definition
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppColors.getBorderColor(isDark: isDark),
                                width: 1,
                              ),
                            ),

                            // ✅ Smooth UX
                            elevation: isSelected ? 2 : 0,
                            pressElevation: 3,

                            onSelected: (_) => cubit.changeCategory(cat),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 14.h),

                    /// -----------------------------
                    /// Podcast List
                    /// -----------------------------
                    Expanded(
                      child: ListView.separated(
                        itemCount: visibleList.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final p = visibleList[index];

                          return InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () {
                              if (p['type'] == "playlist") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider(
                                      create: (_) =>
                                          PodcastCubit(yt: yt),
                                      child: PodcastEpisodesScreen(
                                        title: p['title']!,
                                        playlistIdOrUrl:
                                        p['playlist']!,
                                        coverImage: p['image'],
                                        primaryColor: primary,
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                final episode = Episode(
                                  videoId: p['id']!,
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
                                    builder: (_) =>
                                        PodcastPlayerScreen(
                                            episode: episode),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(18.w),
                              decoration: BoxDecoration(
                                borderRadius:
                                BorderRadius.circular(22),
                                gradient: isDark
                                    ? LinearGradient(
                                  colors: [
                                    Colors.white
                                        .withOpacity(0.06),
                                    Colors.white
                                        .withOpacity(0.03),
                                  ],
                                )
                                    : LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.grey.shade50,
                                  ],
                                ),
                                border: Border.all(
                                  color: primary.withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  /// Thumbnail
                                  ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(18),
                                    child: Image.network(
                                      p['image']!,
                                      width: 110.w,
                                      height: 90.w,
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  SizedBox(width: 16.w),

                                  /// Title
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['title']!,
                                          style:
                                          AppTextStyles.madB16(
                                            context,
                                            color: textClr,
                                          ),
                                        ),
                                        SizedBox(height: 6.h),
                                        Text(
                                          p['type'] == "playlist"
                                              ? "مشاهدة جميع الحلقات"
                                              : "مشاهدة الحلقة",
                                          style:
                                          AppTextStyles.madReg12(
                                            context,
                                            color: textClr
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Icon(
                                    context.locale.languageCode == "ar"
                                        ? Icons.arrow_forward_ios
                                        : Icons
                                        .arrow_back_ios_new_rounded,
                                    color: primary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
