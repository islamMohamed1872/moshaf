// lib/views/quran/add_to_playlist_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/constants/app_colors.dart';

import '../../../controllers/playlist/playlist_cubit.dart';
import '../../../controllers/playlist/playlist_state.dart';

class AddToPlaylistDialog extends StatefulWidget {
  final int surah;
  final int maxVerses;

  const AddToPlaylistDialog({
    Key? key,
    required this.surah,
    required this.maxVerses,
  }) : super(key: key);

  @override
  State<AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<AddToPlaylistDialog> {
  late int startVerse;
  late int endVerse;
  late TextEditingController startController;
  late TextEditingController endController;

  @override
  void initState() {
    super.initState();
    startVerse = 1;
    endVerse = widget.maxVerses;
    startController = TextEditingController(text: '1');
    endController = TextEditingController(text: widget.maxVerses.toString());
  }

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Unified 3-mode colors
    final bgColor = AppColors.lbBg(context);
    final textColor = AppColors.lbText(context);
    final borderColor = AppColors.lbBorder(context);
    final primaryColor = AppColors.lbPrimary();

    final surfaceColor = AppColors.lbSubPanel(context);

    final text2 = textColor.withOpacity(isDark ? 0.65 : 0.7);

    final inputBgColor = AppColors.isGoldMode
        ? const Color(0xffFFF7E6) // soft gold for input fields
        : surfaceColor;

    return BlocBuilder<PlaylistCubit, PlaylistState>(
      builder: (context, state) {
        final cubit = PlaylistCubit.get(context);

        return Dialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'اختر نطاق الآيات',
                    style: AppTextStyles.madB16(context, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سورة ${quran.getSurahNameArabic(widget.surah)}',
                    style: AppTextStyles.madReg12(context, color: text2),
                  ),
                  const SizedBox(height: 24),

                  // Verse Range Selector
                  _buildVerseRangeSection(
                    context: context,
                    textColor: textColor,
                    text2: text2,
                    borderColor: borderColor,
                    inputBgColor: inputBgColor,
                    primaryColor: primaryColor,
                  ),

                  const SizedBox(height: 24),

                  // Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      'ستتم إضافة الآيات من $startVerse إلى $endVerse',
                      style: AppTextStyles.madReg11(context, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Playlists List
                  Text(
                    'اختر القائمة',
                    style: AppTextStyles.madB14(context, color: textColor),
                  ),
                  const SizedBox(height: 12),

                  if (cubit.playlists.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Text(
                        'لا توجد قوائم تشغيل',
                        style: AppTextStyles.madReg12(context, color: text2),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: cubit.playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = cubit.playlists[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              title: Text(
                                playlist.name,
                                style: AppTextStyles.madB12(context, color: textColor),
                              ),
                              subtitle: Text(
                                '${playlist.items.length} عنصر',
                                style: AppTextStyles.madReg10(context, color: text2),
                              ),
                              onTap: () {
                                // ✅ Validate range
                                if (startVerse > endVerse) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('رقم البداية يجب أن يكون أقل من النهاية'),
                                    ),
                                  );
                                  return;
                                }

                                if (startVerse < 1 || endVerse > widget.maxVerses) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'نطاق آيات غير صحيح (1-${widget.maxVerses})',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // ✅ Add to playlist
                                cubit.addItemToPlaylist(
                                  playlist.id,
                                  widget.surah,
                                  startVerse,
                                  endVerse,
                                );

                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'تمت إضافة الآيات ${startVerse}-${endVerse} إلى ${playlist.name}',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            foregroundColor: textColor,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'إلغاء',
                            style: AppTextStyles.madReg12(context, color: textColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showCreatePlaylistDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerseRangeSection({
    required BuildContext context,
    required Color textColor,
    required Color text2,
    required Color borderColor,
    required Color inputBgColor,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نطاق الآيات',
          style: AppTextStyles.madB12(context, color: textColor),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Start Verse Input
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'من الآية',
                    style: AppTextStyles.madReg10(context, color: text2),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: startController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    onChanged: (value) {
                      setState(() {
                        startVerse = int.tryParse(value) ?? 1;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '1',
                      hintStyle: TextStyle(color: text2),
                      filled: true,
                      fillColor: inputBgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 1.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // End Verse Input
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إلى الآية',
                    style: AppTextStyles.madReg10(context, color: text2),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: endController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    onChanged: (value) {
                      setState(() {
                        endVerse = int.tryParse(value) ?? widget.maxVerses;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: widget.maxVerses.toString(),
                      hintStyle: TextStyle(color: text2),
                      filled: true,
                      fillColor: inputBgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 1.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Quick Select Buttons
        Text(
          'اختيار سريع:',
          style: AppTextStyles.madReg10(context, color: text2),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _quickSelectButton(
              context: context,
              label: 'البداية',
              borderColor: primaryColor,
              textColor: primaryColor,
              onTap: () {
                setState(() {
                  startVerse = 1;
                  endVerse = 5;
                  startController.text = '1';
                  endController.text = '5';
                });
              },
            ),
            _quickSelectButton(
              context: context,
              label: 'الوسط',
              borderColor: primaryColor,
              textColor: primaryColor,
              onTap: () {
                int mid = (widget.maxVerses / 2).round();
                setState(() {
                  startVerse = (mid - 2).clamp(1, widget.maxVerses);
                  endVerse = (mid + 2).clamp(1, widget.maxVerses);
                  startController.text = startVerse.toString();
                  endController.text = endVerse.toString();
                });
              },
            ),
            _quickSelectButton(
              context: context,
              label: 'النهاية',
              borderColor: primaryColor,
              textColor: primaryColor,
              onTap: () {
                setState(() {
                  startVerse = (widget.maxVerses - 4).clamp(1, widget.maxVerses);
                  endVerse = widget.maxVerses;
                  startController.text = startVerse.toString();
                  endController.text = endVerse.toString();
                });
              },
            ),
            _quickSelectButton(
              context: context,
              label: 'الكل',
              borderColor: primaryColor,
              textColor: primaryColor,
              onTap: () {
                setState(() {
                  startVerse = 1;
                  endVerse = widget.maxVerses;
                  startController.text = '1';
                  endController.text = widget.maxVerses.toString();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickSelectButton({
    required BuildContext context,
    required String label,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTextStyles.madReg10(context, color: textColor),
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = AppColors.lbBg(context);
    final textColor = AppColors.lbText(context);
    final borderColor = AppColors.lbBorder(context);
    final primaryColor = AppColors.lbPrimary();
    final surfaceColor = AppColors.lbSubPanel(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
          decoration: InputDecoration(
            hintText: 'اسم القائمة',
            hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
            filled: true,
            fillColor: AppColors.isGoldMode
                ? const Color(0xffFFF7E6)
                : surfaceColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 1.3),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final cubit = PlaylistCubit.get(context);
                cubit.createPlaylist(controller.text.trim());

                // Add current range to new playlist
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (cubit.playlists.isEmpty) return;
                  final newPlaylist = cubit.playlists.last;
                  cubit.addItemToPlaylist(
                    newPlaylist.id,
                    widget.surah,
                    startVerse,
                    endVerse,
                  );
                });

                Navigator.pop(ctx);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم إنشاء القائمة وإضافة الآيات ${startVerse}-${endVerse}',
                    ),
                  ),
                );
              }
            },
            child: Text('إنشاء', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }
}
