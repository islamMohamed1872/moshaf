// lib/views/quran/widgets/custom_sorah_container.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:quran/quran.dart' as quran;
import '../../../constants/app_textstyles.dart';
import '../../../controllers/playlist/playlist_cubit.dart';
import '../../../controllers/playlist/playlist_state.dart';
import 'add_to_playlist_dialog.dart';

class CustomSorahContainer extends StatelessWidget {
  final int sorahIndex;
  final String placeOfRevelation;
  final int verseCount;
  final VoidCallback onReadPressed;
  final VoidCallback onRowPressed;
  final VoidCallback onListenPressed;
  final Color? borderColor;
  final double? height;
  final bool isDark;
  final bool? showPlayListIcon;

  const CustomSorahContainer({
    super.key,
    required this.placeOfRevelation,
    required this.verseCount,
    required this.sorahIndex,
    required this.onRowPressed,
    required this.onReadPressed,
    required this.onListenPressed,
    this.borderColor,
    this.height,
    required this.isDark, this.showPlayListIcon,
  });

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.isGoldMode;
    final surah = sorahIndex + 1;

    // Colors
    final borderClr = borderColor ??
        (gold
            ? const Color(AppColors.goldBorder)
            : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders));

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final subTextClr = gold
        ? const Color(AppColors.goldText)
        : Color(isDark ? AppColors.containerDarkBorders : 0xff848484);

    final iconClr = gold ? const Color(AppColors.goldPrimary) : (isDark ? Colors.white : Colors.black);

    final playButtonColor = gold ? const Color(AppColors.goldPrimary) : const Color(0xff0F9D58);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: borderClr),
      ),
      child: InkWell(
        onTap: onRowPressed,
        child: Row(
          spacing: 8.w,
          children: [
            /// LEFT - Surah Number / Metadata
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: surah.toString(),
                    style: AppTextStyles.arsura24(context, color: textClr),
                  ),
                ),
                Text(
                  "$placeOfRevelation | $verseCount آيات",
                  style: AppTextStyles.madXL10(context, color: subTextClr),
                ),
              ],
            ),

            const Spacer(),

            /// READ BUTTON
            InkWell(
              onTap: onReadPressed,
              child: Icon(
                FontAwesomeIcons.solidFileLines,
                color: iconClr,
                size: 20,
              ),
            ),

            /// ADD TO PLAYLIST BUTTON WITH MENU
            if(showPlayListIcon!=false)
            _buildPlaylistMenu(context, surah, gold, iconClr, textClr, borderClr),

            /// LISTEN BUTTON
            InkWell(
              onTap: onListenPressed,
              child: Container(
                width: 25.w,
                height: 25.w,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: playButtonColor,
                ),
                child: const FittedBox(
                  child: Icon(
                    FontAwesomeIcons.play,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistMenu(
      BuildContext context,
      int surah,
      bool gold,
      Color iconClr,
      Color textClr,
      Color borderClr,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Menu background (different from page bg)
    final menuBg = gold
        ? const Color(0xffFFF7E6) // warm gold surface
        : (isDark ? const Color(0xff1E1E1E) : Colors.white);

    // ✅ Menu text (ensure contrast)
    final menuText = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    // ✅ Menu icons (highlight)
    final menuIcon = gold
        ? const Color(AppColors.goldPrimary)
        : (isDark ? Colors.white : Colors.black);

    // ✅ Divider
    final menuDivider = gold
        ? const Color(AppColors.goldBorder)
        : (isDark ? Colors.white12 : Colors.black12);

    return PopupMenuButton<String>(
      icon: Icon(Icons.playlist_add, color: iconClr, size: 20),

      // ✅ IMPORTANT: force bg color
      color: menuBg,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: menuDivider),
      ),

      onSelected: (value) {
        if (value == 'full') {
          _showAddFullSurahDialog(context, surah);
        } else if (value == 'range') {
          _showAddRangeDialog(context, surah);
        }
      },

      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'full',
          child: Row(
            children: [
              Icon(Icons.done_all, size: 18, color: menuIcon),
              const SizedBox(width: 10),
              Text(
                'إضافة السورة كاملة',
                style: AppTextStyles.madReg12(context, color: menuText),
              ),
            ],
          ),
        ),

        // PopupMenuDivider(height: 10),
        //
        // PopupMenuItem<String>(
        //   value: 'range',
        //   child: Row(
        //     children: [
        //       Icon(Icons.select_all, size: 18, color: menuIcon),
        //       const SizedBox(width: 10),
        //       Text(
        //         'إضافة نطاق معين',
        //         style: AppTextStyles.madReg12(context, color: menuText),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }


  void _showAddFullSurahDialog(BuildContext context, int surah) {
    final verseCount = quran.getVerseCount(surah);

    // ✅ 3-mode colors
    final bgColor = AppColors.lbBg(context);
    final textColor = AppColors.lbText(context);
    final borderColor = AppColors.lbBorder(context);
    final primary = AppColors.lbPrimary();
    final surface = AppColors.lbSubPanel(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        title: Text(
          'اختر القائمة',
          style: AppTextStyles.madB14(context, color: textColor),
        ),
        content: BlocBuilder<PlaylistCubit, PlaylistState>(
          builder: (context, state) {
            final cubit = PlaylistCubit.get(context);

            if (cubit.playlists.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  'لا توجد قوائم. أنشئ قائمة جديدة أولاً',
                  style: AppTextStyles.madReg12(context, color: textColor),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return SizedBox(
              height: 240,
              width: double.maxFinite,
              child: ListView.separated(
                itemCount: cubit.playlists.length,
                separatorBuilder: (_, __) => Divider(color: borderColor),
                itemBuilder: (context, index) {
                  final playlist = cubit.playlists[index];

                  return Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        playlist.name,
                        style: AppTextStyles.madB12(context, color: textColor),
                      ),
                      subtitle: Text(
                        '${playlist.items.length} عنصر',
                        style: AppTextStyles.madReg10(
                          context,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      trailing: Icon(Icons.add, color: primary),
                      onTap: () {
                        cubit.addItemToPlaylist(
                          playlist.id,
                          surah,
                          1,
                          verseCount,
                        );

                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تمت الإضافة إلى ${playlist.name}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
        actionsPadding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'إلغاء',
                    style: AppTextStyles.madReg12(context, color: textColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showCreatePlaylistDialog(context, surah, true),
                  child: Text(
                    'قائمة جديدة',
                    style: AppTextStyles.madReg12(context, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _showAddRangeDialog(BuildContext context, int surah) {
    final verseCount = quran.getVerseCount(surah);

    showDialog(
      context: context,
      builder: (ctx) => AddToPlaylistDialog(
        surah: surah,
        maxVerses: verseCount,
      ),
    );
  }

  void _showCreatePlaylistDialog(
      BuildContext context,
      int surah,
      bool isFullSurah,
      ) {
    final controller = TextEditingController();
    final verseCount = quran.getVerseCount(surah);

    // ✅ 3-mode colors
    final bgColor = AppColors.lbBg(context);
    final textColor = AppColors.lbText(context);
    final borderColor = AppColors.lbBorder(context);
    final primary = AppColors.lbPrimary();
    final surface = AppColors.lbSubPanel(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        title: Text(
          'إنشاء قائمة جديدة',
          style: AppTextStyles.madB14(context, color: textColor),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: textColor),
          cursorColor: primary,
          decoration: InputDecoration(
            hintText: 'اسم القائمة',
            hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
            filled: true,
            fillColor: AppColors.isGoldMode ? const Color(0xffFFF7E6) : surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 1.4),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'إلغاء',
                    style: AppTextStyles.madReg12(context, color: textColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;

                    final cubit = PlaylistCubit.get(context);
                    cubit.createPlaylist(name);

                    // ✅ Add to the newly created playlist
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (cubit.playlists.isEmpty) return;
                      final newPlaylist = cubit.playlists.last;

                      cubit.addItemToPlaylist(
                        newPlaylist.id,
                        surah,
                        1,
                        isFullSurah ? verseCount : 1,
                      );
                    });

                    Navigator.pop(ctx);
                    Navigator.pop(context); // Close previous dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إنشاء القائمة وإضافة السورة'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Text(
                    'إنشاء',
                    style: AppTextStyles.madReg12(context, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}