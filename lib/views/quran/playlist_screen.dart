// lib/views/quran/playlist_screen.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran/quran.dart';
import 'package:moshaf/controllers/quran_audio/audio_quran_cubit.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/constants/app_colors.dart';

import '../../components/audio_service.dart';
import '../../components/components.dart';
import '../../controllers/playlist/playlist_cubit.dart';
import '../../controllers/playlist/playlist_state.dart';
import '../../controllers/text_quran/text_quran_cubit.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../../models/playlist_model.dart';
import 'widgets/quran_page.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PlaylistCubit.get(context).loadPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    final gold   = AppColors.isGoldMode;

    final borderClr  = gold ? const Color(AppColors.goldBorder) : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);
    final textClr    = gold ? const Color(AppColors.goldText)   : (isDark ? Colors.white : Colors.black);
    final backIconClr = gold ? const Color(AppColors.goldAccent) : Colors.white;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ░░░░░░ HEADER ░░░░░░
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  "assets/images/sorah_bg.png",
                  height: 220.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  width: double.infinity,
                  height: 220.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0),
                        gold ? const Color(AppColors.goldBackground)
                            : (isDark ? const Color(0xFF151515) : Colors.white),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0, right: 0, left: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _showCreatePlaylistDialog(context, isDark),
                          child: Container(
                            width: 35.w,
                            height: 35.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: backIconClr),
                            ),
                            child: Icon(Icons.add, color: backIconClr, size: 18.w),
                          ),
                        ),
                        Text(
                          "قوائم التشغيل",
                          style: AppTextStyles.arsura24(context,
                              color: gold ? const Color(AppColors.goldAccent) : Colors.white),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 30.w,
                            height: 30.w,
                            padding: EdgeInsetsDirectional.only(
                              start: context.locale.languageCode == "ar" ? 0 : 7.w,
                              top: 5, bottom: 5,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: backIconClr),
                            ),
                            child: FittedBox(
                              child: Icon(
                                context.locale.languageCode == "ar"
                                    ? Icons.arrow_forward_ios
                                    : Icons.arrow_back_ios,
                                color: backIconClr,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  child: Text(
                    "اختر قائمة تشغيل أو أنشئ واحدة جديدة",
                    style: AppTextStyles.madReg12(context,
                        color: Colors.white.withOpacity(0.85)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            Container(width: double.infinity, height: 1, color: borderClr),

            // ░░░░░░ BODY ░░░░░░
            Expanded(
              child: BlocBuilder<PlaylistCubit, PlaylistState>(
                builder: (context, state) {
                  final cubit = PlaylistCubit.get(context);

                  if (state is PlaylistLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: gold ? const Color(AppColors.goldPrimary)
                            : const Color(AppColors.mainGreen),
                      ),
                    );
                  }

                  if (cubit.playlists.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.playlist_play,
                              size: 70, color: textClr.withOpacity(0.5)),
                          SizedBox(height: 12.h),
                          Text('لا توجد قوائم تشغيل',
                              style: AppTextStyles.madReg14(context, color: textClr)),
                          SizedBox(height: 16.h),
                          InkWell(
                            onTap: () =>
                                _showCreatePlaylistDialog(context, isDark),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 18.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: gold
                                    ? const Color(AppColors.goldPrimary)
                                    : const Color(AppColors.mainGreen),
                              ),
                              child: Text("إنشاء قائمة",
                                  style: AppTextStyles.madB14(context,
                                      color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 15.w, vertical: 12.h),
                    child: ListView.separated(
                      itemCount: cubit.playlists.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final playlist = cubit.playlists[index];
                        return _PlaylistTileAllQuranStyle(
                          playlist: playlist,
                          isDark: isDark,
                          borderClr: borderClr,
                          textClr: textClr,
                          gold: gold,
                          onTap: () =>
                              _openPlaylistDetails(context, playlist, cubit),
                          onDelete: () => _showDeleteConfirmation(
                              context, cubit, playlist, isDark),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── dialogs ────────────────────────────────────────────────────────────────
  void _showCreatePlaylistDialog(BuildContext context, bool isDark) {
    final controller = TextEditingController();
    final gold = AppColors.isGoldMode;

    final bgColor    = gold ? const Color(AppColors.goldBackground) : (isDark ? const Color(0xFF151515) : Colors.white);
    final textColor  = gold ? const Color(AppColors.goldText)       : (isDark ? Colors.white : Colors.black);
    final borderColor = gold ? const Color(AppColors.goldBorder)    : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor),
        ),
        title: Text('إنشاء قائمة جديدة',
            style: AppTextStyles.madB14(context, color: textColor)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'اسم القائمة',
            hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
            filled: true,
            fillColor: gold
                ? const Color(0xffFFF7E6)
                : Colors.grey.withOpacity(0.1),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: gold
                        ? const Color(AppColors.goldPrimary)
                        : const Color(AppColors.mainGreen),
                    width: 1.2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              PlaylistCubit.get(context).createPlaylist(name);
              Navigator.pop(ctx);
            },
            child: Text(
              'إنشاء',
              style: TextStyle(
                  color: gold
                      ? const Color(AppColors.goldPrimary)
                      : const Color(AppColors.mainGreen)),
            ),
          ),
        ],
      ),
    );
  }

  void _openPlaylistDetails(BuildContext context, Playlist playlist,
      PlaylistCubit cubit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistDetailsScreen(
          playlist: playlist,
          cubit: cubit,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PlaylistCubit cubit,
      Playlist playlist, bool isDark) {
    final gold       = AppColors.isGoldMode;
    final bgColor    = gold ? const Color(AppColors.goldBackground) : (isDark ? const Color(0xFF151515) : Colors.white);
    final textColor  = gold ? const Color(AppColors.goldText)       : (isDark ? Colors.white : Colors.black);
    final borderColor = gold ? const Color(AppColors.goldBorder)    : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor),
        ),
        title: Text('حذف القائمة',
            style: AppTextStyles.madB14(context, color: textColor)),
        content: Text('هل أنت متأكد من حذف "${playlist.name}"؟',
            style: AppTextStyles.madReg12(context, color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              cubit.deletePlaylist(playlist.id);
              Navigator.pop(ctx);
            },
            child:
            const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Playlist tile ──────────────────────────────────────────────────────────────
class _PlaylistTileAllQuranStyle extends StatelessWidget {
  final Playlist playlist;
  final bool isDark;
  final Color borderClr;
  final Color textClr;
  final bool gold;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlaylistTileAllQuranStyle({
    required this.playlist,
    required this.isDark,
    required this.borderClr,
    required this.textClr,
    required this.gold,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bg = gold
        ? const Color(0xffFFF7E6)
        : (isDark ? const Color(0xFF1B1B1B) : Colors.white);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding:
        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderClr),
        ),
        child: Row(
          children: [
            Container(
              width: 45.w,
              height: 45.w,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderClr)),
              child: Icon(
                Icons.playlist_play,
                color: gold
                    ? const Color(AppColors.goldPrimary)
                    : const Color(AppColors.mainGreen),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.madB14(context, color: textClr),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    "${playlist.items.length} عنصر",
                    style: AppTextStyles.madReg10(context,
                        color: textClr.withOpacity(0.65)),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Playlist details screen ────────────────────────────────────────────────────
class PlaylistDetailsScreen extends StatelessWidget {
  final Playlist playlist;
  final PlaylistCubit cubit;

  const PlaylistDetailsScreen({
    super.key,
    required this.playlist,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    final gold   = AppColors.isGoldMode;

    final borderClr   = gold ? const Color(AppColors.goldBorder) : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);
    final textClr     = gold ? const Color(AppColors.goldText)   : (isDark ? Colors.white : Colors.black);
    final backIconClr = gold ? const Color(AppColors.goldAccent) : Colors.white;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<PlaylistCubit, PlaylistState>(
          builder: (context, state) {
            // keep a fresh reference in case the playlist was mutated
            final freshPlaylist = PlaylistCubit.get(context)
                .playlists
                .firstWhere((p) => p.id == playlist.id,
                orElse: () => playlist);

            return Column(
              children: [
                // ── header ──────────────────────────────────────────────
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      "assets/images/sorah_bg.png",
                      height: 220.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      width: double.infinity,
                      height: 220.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0),
                            gold
                                ? const Color(AppColors.goldBackground)
                                : (isDark
                                ? const Color(0xFF151515)
                                : Colors.white),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0, right: 0, left: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // play all
                            InkWell(
                              onTap: () => _playPlaylist(context, freshPlaylist),
                              child: Icon(
                                Icons.play_circle_fill,
                                size: 26.w,
                                color: gold
                                    ? const Color(AppColors.goldAccent)
                                    : Colors.white,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                child: Text(
                                  freshPlaylist.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.arsura24(context,
                                      color: gold
                                          ? const Color(AppColors.goldAccent)
                                          : Colors.white),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 30.w,
                                height: 30.w,
                                padding: EdgeInsetsDirectional.only(
                                  start: context.locale.languageCode == "ar"
                                      ? 0
                                      : 7.w,
                                  top: 5, bottom: 5,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: backIconClr),
                                ),
                                child: FittedBox(
                                  child: Icon(
                                    context.locale.languageCode == "ar"
                                        ? Icons.arrow_forward_ios
                                        : Icons.arrow_back_ios,
                                    color: backIconClr,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 15,
                      child: Text(
                        "${freshPlaylist.items.length} عنصر",
                        style: AppTextStyles.madReg12(context,
                            color: Colors.white.withOpacity(0.85)),
                      ),
                    ),
                  ],
                ),

                Container(width: double.infinity, height: 1, color: borderClr),

                // ── content ─────────────────────────────────────────────
                Expanded(
                  child: freshPlaylist.items.isEmpty
                      ? Center(
                    child: Text('لا توجد عناصر في القائمة',
                        style: AppTextStyles.madReg14(context,
                            color: textClr)),
                  )
                      : Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 15.w, vertical: 12.h),
                    child: ListView.separated(
                      itemCount: freshPlaylist.items.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final item = freshPlaylist.items[index];
                        final surahName =
                        quran.getSurahNameArabic(item.surah);

                        return _PlaylistItemTileAllQuranStyle(
                          index: index,
                          surahName: surahName,
                          item: item,
                          isDark: isDark,
                          gold: gold,
                          borderClr: borderClr,
                          textClr: textClr,
                          onPlay: () =>
                              _playItem(context, item),
                          // ✅ NEW: read navigation
                          onRead: () async {
                            AudioQuranCubit.get(context).stop();
                            await AudioServices()
                                .player
                                .clearAudioSources();
                            TextQuranCubit.get(context).soraNumber =
                                item.surah;
                            navigateTo(
                              context,
                              QuranViewPage(
                                navigatedFromRecitation: false,
                                shouldHighlightText: false,
                                highlightVerse: "",
                                jsonData: TextQuranCubit.get(context)
                                    .suraJsonData,
                                pageNumber: getPageNumber(
                                    item.surah, item.startVerse),
                              ),
                            );
                          },
                          onDelete: () => cubit.removeItemFromPlaylist(
                              freshPlaylist.id, index),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _playItem(BuildContext context, PlaylistItem item) {
    AudioQuranCubit.get(context).playPlaylistItem(item);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'جاري التشغيل: ${quran.getSurahNameArabic(item.surah)} (${item.startVerse}-${item.endVerse})'),
      duration: const Duration(seconds: 2),
    ));
  }

  void _playPlaylist(BuildContext context, Playlist p) {
    AudioQuranCubit.get(context).playPlaylist(p);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('جاري تشغيل قائمة: ${p.name}'),
      duration: const Duration(seconds: 2),
    ));
  }
}

// ── playlist item tile (updated with read button) ──────────────────────────────
class _PlaylistItemTileAllQuranStyle extends StatelessWidget {
  final int index;
  final String surahName;
  final PlaylistItem item;

  final bool isDark;
  final bool gold;
  final Color borderClr;
  final Color textClr;

  final VoidCallback onPlay;
  final VoidCallback onRead;   // ✅ new
  final VoidCallback onDelete;

  const _PlaylistItemTileAllQuranStyle({
    required this.index,
    required this.surahName,
    required this.item,
    required this.isDark,
    required this.gold,
    required this.borderClr,
    required this.textClr,
    required this.onPlay,
    required this.onRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bg = gold
        ? const Color(0xffFFF7E6)
        : (isDark ? const Color(0xFF1B1B1B) : Colors.white);

    final primary = gold
        ? const Color(AppColors.goldPrimary)
        : const Color(AppColors.mainGreen);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderClr),
      ),
      child: Row(
        children: [
          // index circle
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderClr)),
            child: Center(
              child: Text(
                (index + 1).toString(),
                style: AppTextStyles.madB14(context, color: primary),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surahName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.madB14(context, color: textClr),
                ),
                SizedBox(height: 4.h),
                Text(
                  'الآية ${item.startVerse} إلى ${item.endVerse}',
                  style: AppTextStyles.madReg10(context,
                      color: textClr.withOpacity(0.65)),
                ),
              ],
            ),
          ),

          // ✅ read icon
          IconButton(
            tooltip: 'قراءة',
            icon: Icon(Icons.menu_book_outlined, color: primary, size: 20),
            onPressed: onRead,
          ),

          // play icon
          IconButton(
            tooltip: 'تشغيل',
            icon: Icon(Icons.play_arrow, color: primary),
            onPressed: onPlay,
          ),

          // delete icon
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}