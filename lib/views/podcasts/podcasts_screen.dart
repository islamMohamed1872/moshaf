import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/podcast/podcast_cubit.dart';
import 'package:moshaf/controllers/podcast/podcast_states.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';
import 'package:moshaf/models/episode_model.dart';
import 'package:moshaf/services/youtube_services.dart';
import 'package:moshaf/views/widgets/header.dart';

import '../widgets/app_toast.dart';
import 'episode_player_screen.dart';
import 'podcast_episodes_screen.dart';

// ── Sort options ──────────────────────────────────────────────────────────────

class PodcastsScreen extends StatelessWidget {
  final _searchController = TextEditingController();

  // ── Suggest playlist bottom sheet ─────────────────────────────────────────
  void _showSuggestSheet(BuildContext context, bool isDark,YouTubeService yt) {
    final urlCtrl  = TextEditingController();
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final primary  = AppColors.getPrimaryColor();
    final textClr  = AppColors.getTextColor(isDark: isDark);
    final borderClr = AppColors.getBorderColor(isDark: isDark);
    final bgClr = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (context) => PodcastCubit(yt: yt),
        child: BlocBuilder<PodcastCubit,PodcastStates>(
          builder: (context, state) {
            final cubit = PodcastCubit.get(context);
            bool submitted = state is SuggestPodcastSuccessState;
            bool loading   = state is SuggestPodcastLoadingState;

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: bgClr,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 28.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: borderClr,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    Row(children: [
                      Icon(Icons.playlist_add_rounded,
                          color: primary, size: 22.sp),
                      SizedBox(width: 8.w),
                      Text("اقتراح قائمة تشغيل",
                          style: AppTextStyles.madB16(context, color: textClr)),
                    ]),

                    SizedBox(height: 6.h),

                    Text(
                      "شاركنا رابط قناة أو قائمة تشغيل على يوتيوب",
                      style: AppTextStyles.madReg12(context,
                          color: textClr.withValues(alpha: 0.55)),
                    ),

                    SizedBox(height: 18.h),

                    if (!submitted) ...[
                      // YouTube URL field
                      _SuggestField(
                        controller: urlCtrl,
                        label: "رابط يوتيوب *",
                        hint: "https://youtube.com/playlist?list=...",
                        icon: Icons.link_rounded,
                        isDark: isDark,
                        primary: primary,
                        textClr: textClr,
                        borderClr: borderClr,
                        keyboardType: TextInputType.url,
                      ),

                      SizedBox(height: 12.h),

                      // Display name field
                      _SuggestField(
                        controller: nameCtrl,
                        label: "اسم القائمة (اختياري)",
                        hint: "مثال: دروس ابن عثيمين",
                        icon: Icons.title_rounded,
                        isDark: isDark,
                        primary: primary,
                        textClr: textClr,
                        borderClr: borderClr,
                      ),

                      SizedBox(height: 12.h),

                      // Note field
                      _SuggestField(
                        controller: noteCtrl,
                        label: "ملاحظة (اختياري)",
                        hint: "سبب الاقتراح أو وصف مختصر",
                        icon: Icons.notes_rounded,
                        isDark: isDark,
                        primary: primary,
                        textClr: textClr,
                        borderClr: borderClr,
                        maxLines: 2,
                      ),

                      SizedBox(height: 20.h),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: loading
                              ? null
                              : () async {
                            final url = urlCtrl.text.trim();
                            if (url.isEmpty ||
                                (!url.contains('youtube') &&
                                    !url.contains('youtu.be'))) {

                              showAppToast(
                                message: "الرجاء إدخال رابط يوتيوب صحيح",
                                isError: true,
                              );
                              return;
                            }
                            // Send suggestion — replace with your actual
                            // Firebase / email / API call
                            await cubit.submitSuggestion(
                              url:  url,
                              name: nameCtrl.text.trim(),
                              note: noteCtrl.text.trim(),
                            );
                          },
                          child: loading
                              ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : Text("إرسال الاقتراح",
                              style: AppTextStyles.madB14(context,
                                  color: Colors.white)),
                        ),
                      ),
                    ] else ...[
                      // Success state
                      Center(
                        child: Column(children: [
                          SizedBox(height: 12.h),
                          Container(
                            width: 60.w,
                            height: 60.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withValues(alpha: 0.1),
                            ),
                            child: Icon(Icons.check_rounded,
                                color: primary, size: 30.sp),
                          ),
                          SizedBox(height: 14.h),
                          Text("شكراً على اقتراحك!",
                              style: AppTextStyles.madB16(context,
                                  color: textClr)),
                          SizedBox(height: 6.h),
                          Text(
                            "سنراجع الاقتراح وقد نضيفه قريباً بإذن الله",
                            style: AppTextStyles.madReg12(context,
                                color: textClr.withValues(alpha: 0.55)),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20.h),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("حسناً",
                                style: AppTextStyles.madReg14(context,
                                    color: primary)),
                          ),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Submission logic — replace body with your Firebase/email call ─────────


  @override
  Widget build(BuildContext context) {
    final isDark    = ThemeCubit.get(context).isDark;
    final borderClr = AppColors.getBorderColor(isDark: isDark);
    final textClr   = AppColors.getTextColor(isDark: isDark);
    final primary   = AppColors.getPrimaryColor();
    // final bgClr     = AppColors.getBackgroundColor(isDark: isDark);

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    final yt     = YouTubeService(apiKey: apiKey);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: BlocProvider(
            create: (_) => PodcastCubit(yt: yt)..getPodcasts(),
            child: BlocBuilder<PodcastCubit, PodcastStates>(
              builder: (context, state) {
                final cubit = PodcastCubit.get(context);
                final displayList = cubit.filteredList;

                return Column(
                  children: [

                    // ── Header + suggest button ─────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Header(
                            title: "مقاطع الفيديو",
                            isDark: isDark,
                            iconColor: textClr,
                          ),
                        ),
                        // Suggest playlist button
                        InkWell(
                          onTap: () => _showSuggestSheet(context, isDark,yt),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 7.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: primary.withValues(alpha: 0.35)),
                              color: primary.withValues(alpha: 0.07),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.playlist_add_rounded,
                                    color: primary, size: 16.sp),
                                SizedBox(width: 5.w),
                                Text("اقتراح",
                                    style: AppTextStyles.madReg12(context,
                                        color: primary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // ── Search ──────────────────────────────────────────
                    Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: AppColors.isGoldMode
                            ? const Color(AppColors.goldBackground)
                            : (isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white),
                        border: Border.all(
                          color: AppColors.isGoldMode
                              ? const Color(AppColors.goldBorder)
                              : borderClr.withValues(alpha: 0.7),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: TextFormField(
                          controller: _searchController,
                          onChanged: cubit.search,
                          cursorColor: primary,
                          style:
                          TextStyle(color: textClr, fontSize: 15.sp),
                          decoration: InputDecoration(
                            icon: Icon(Icons.search, color: primary),
                            hintText: "بحث",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // ── Category chips + sort button ────────────────────
                    Row(
                      children: [
                        // Category chips (scrollable if needed)
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                              PodcastCategory.values.map((cat) {
                                final bool isSelected =
                                    cubit.selectedCategory == cat;

                                final label = switch (cat) {
                                  PodcastCategory.all   => "الكل",
                                  PodcastCategory.deen  => "دِين",
                                  PodcastCategory.dunya => "دُنْيَا",
                                };

                                return Padding(
                                  padding: EdgeInsets.only(left: 8.w),
                                  child: ChoiceChip(
                                    label: Text(label,
                                        style: AppTextStyles.madReg14(
                                          context,
                                          color: isSelected
                                              ? Colors.white
                                              : textClr,
                                        )),
                                    selected: isSelected,
                                    selectedColor: primary,
                                    backgroundColor: AppColors.isGoldMode
                                        ? const Color(
                                        AppColors.goldBackground)
                                        : isDark
                                        ? Colors.black
                                        .withValues(alpha: 0.7)
                                        : Colors.grey.shade200,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: isSelected
                                            ? Colors.transparent
                                            : borderClr,
                                      ),
                                    ),
                                    elevation: isSelected ? 2 : 0,
                                    pressElevation: 3,
                                    onSelected: (_) =>
                                        cubit.changeCategory(cat),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        SizedBox(width: 8.w),

                        // Sort button
                        _SortButton(
                          sort: cubit.selectedSort,
                          primary: primary,
                          textClr: textClr,
                          borderClr: borderClr,
                          isDark: isDark,
                          onChanged: (s) => cubit.changeSort(s),
                        ),
                      ],
                    ),

                    SizedBox(height: 14.h),

                    // ── Active sort label ───────────────────────────────
                    if (cubit.selectedSort != PodcastSort.none)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(children: [
                          Icon(Icons.sort_rounded,
                              size: 14.sp,
                              color: primary),
                          SizedBox(width: 4.w),
                          Text(
                            cubit.selectedSort == PodcastSort.newest
                                ? "مرتب من الأحدث"
                                : "مرتب من الأقدم",
                            style: AppTextStyles.madReg12(context,
                                color: textClr.withValues(alpha: 0.55)),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () =>
                                cubit.changeSort(PodcastSort.none),
                            child: Text("إلغاء",
                                style: AppTextStyles.madReg12(context,
                                    color: primary)),
                          ),
                        ]),
                      ),

                    // ── Podcast list ────────────────────────────────────
                    ConditionalBuilder(
                      condition: state is! GetPodcastsLoadingStates,
                      builder: (context) => Expanded(
                        child: displayList.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 40.sp,
                                  color:
                                  textClr.withValues(alpha: 0.3)),
                              SizedBox(height: 10.h),
                              Text("لا توجد نتائج",
                                  style: AppTextStyles.madReg14(
                                      context,
                                      color: textClr
                                          .withValues(alpha: 0.45))),
                            ],
                          ),
                        )
                            : ListView.separated(
                          itemCount: displayList.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final p = displayList[index];
                            return _PodcastCard(
                              p: p,
                              yt: yt,
                              isDark: isDark,
                              textClr: textClr,
                              primary: primary,
                            );
                          },
                        ),
                      ),
                      fallback: (context) => Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                              color: primary),
                        ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Sort button
// ─────────────────────────────────────────────────────────────────────────────

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.sort,
    required this.primary,
    required this.textClr,
    required this.borderClr,
    required this.onChanged,
    required this.isDark,
  });

  final PodcastSort sort;
  final Color primary, textClr, borderClr;
  final ValueChanged<PodcastSort> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isActive = sort != PodcastSort.none;

    return PopupMenuButton<PodcastSort>(
      onSelected: onChanged,
      color: isDark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: PodcastSort.newest,
          child: Row(children: [
            Icon(Icons.arrow_downward_rounded,
                size: 16, color: sort == PodcastSort.newest ? primary : textClr),
            SizedBox(width: 8.w),
            Text("الأحدث أولاً",
                style: AppTextStyles.madReg14(context,
                    color: sort == PodcastSort.newest ? primary : textClr)),
          ]),
        ),
        PopupMenuItem(
          value: PodcastSort.oldest,
          child: Row(children: [
            Icon(Icons.arrow_upward_rounded,
                size: 16, color: sort == PodcastSort.oldest ? primary : textClr),
            SizedBox(width: 8.w),
            Text("الأقدم أولاً",
                style: AppTextStyles.madReg14(context,
                    color: sort == PodcastSort.oldest ? primary : textClr)),
          ]),
        ),
        PopupMenuItem(
          value: PodcastSort.none,
          child: Row(children: [
            Icon(Icons.clear_rounded,
                size: 16, color: textClr.withValues(alpha: 0.5)),
            SizedBox(width: 8.w),
            Text("بدون ترتيب",
                style: AppTextStyles.madReg14(context,
                    color: textClr.withValues(alpha: 0.5))),
          ]),
        ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive ? primary.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isActive ? primary : borderClr,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.sort_rounded,
              size: 16.sp, color: isActive ? primary : textClr),
          SizedBox(width: 4.w),
          Text("ترتيب",
              style: AppTextStyles.madReg12(context,
                  color: isActive ? primary : textClr)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Suggest sheet text field
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestField extends StatelessWidget {
  const _SuggestField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    required this.primary,
    required this.textClr,
    required this.borderClr,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool isDark;
  final Color primary, textClr, borderClr;
  final TextInputType keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.madReg12(context,
                color: textClr.withValues(alpha: 0.6))),
        SizedBox(height: 5.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          cursorColor: primary,
          style: AppTextStyles.madReg14(context, color: textClr),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.madReg12(context,
                color: textClr.withValues(alpha: 0.3)),
            prefixIcon: Icon(icon, color: primary, size: 18.sp),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderClr),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderClr),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Podcast card (extracted to keep build() clean)
// ─────────────────────────────────────────────────────────────────────────────

class _PodcastCard extends StatelessWidget {
  const _PodcastCard({
    required this.p,
    required this.yt,
    required this.isDark,
    required this.textClr,
    required this.primary,
  });

  final Map<String, dynamic> p;
  final YouTubeService yt;
  final bool isDark;
  final Color textClr, primary;

  @override
  Widget build(BuildContext context) {
    // Format publishedAt for display
    String? dateLabel;
    final raw = p['publishedAt'];
    if (raw != null && raw.isNotEmpty) {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        dateLabel = DateFormat('d MMM yyyy', 'ar').format(dt);
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        if (p['type'] == "playlist") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => PodcastCubit(yt: yt),
                child: PodcastEpisodesScreen(
                  title: p['title']!,
                  playlistIdOrUrl: p['playlist']!,
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
              builder: (_) => PodcastPlayerScreen(episode: episode),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: isDark
              ? LinearGradient(colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.03),
          ])
              : LinearGradient(colors: [
            Colors.white,
            Colors.grey.shade50,
          ]),
          border: Border.all(color: primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                p['image']!,
                width: 110.w,
                height: 90.w,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 110.w,
                  height: 90.w,
                  color: primary.withValues(alpha: 0.1),
                  child: Icon(Icons.play_circle_outline_rounded,
                      color: primary, size: 32.sp),
                ),
              ),
            ),

            SizedBox(width: 16.w),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['title']!,
                    style: AppTextStyles.madB16(context, color: textClr),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    p['type'] == "playlist"
                        ? "مشاهدة جميع الحلقات"
                        : "مشاهدة الحلقة",
                    style: AppTextStyles.madReg12(context,
                        color: textClr.withValues(alpha: 0.6)),
                  ),
                  // Date badge
                  if (dateLabel != null) ...[
                    SizedBox(height: 6.h),
                    Row(children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 11.sp,
                          color: textClr.withValues(alpha: 0.4)),
                      SizedBox(width: 4.w),
                      Text(dateLabel,
                          style: AppTextStyles.madReg10(context,
                              color: textClr.withValues(alpha: 0.4))),
                    ]),
                  ],
                ],
              ),
            ),

            Icon(
              context.locale.languageCode == "ar"
                  ? Icons.arrow_forward_ios
                  : Icons.arrow_back_ios_new_rounded,
              color: primary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}