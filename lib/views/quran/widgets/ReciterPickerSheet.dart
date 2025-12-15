import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_textstyles.dart';
import '../../../controllers/quran_audio/audio_quran_cubit.dart';
import '../../../controllers/quran_audio/audio_quran_states.dart';

class ReciterPickerSheet extends StatelessWidget {
  const ReciterPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = AudioQuranCubit.get(context);
    final isDark = ThemeCubit.get(context).isDark;
    final gold = AppColors.isGoldMode;
    
    final bgColor = gold
        ? const Color(AppColors.goldBackground)
        : (isDark ?const Color(0xFF151515) : Colors.white);

    final textColor = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final borderColor = gold
        ? const Color(AppColors.goldBorder)
        : (isDark
        ? const Color(AppColors.containerDarkBorders)
        : const Color(AppColors.containerLightBorders));

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75, // 🔽 Reduced height
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            // ─── Drag Handle ───────────────────────────────
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // ─── Title ────────────────────────────────────
            Text(
              "اختر القارئ",
              style: AppTextStyles.madB16(context, color: textColor),
            ),

            const SizedBox(height: 12),

            // 🔍 Search
            TextField(
              onChanged: cubit.searchSheikh,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'ابحث عن القارئ',
                hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: textColor.withOpacity(0.6)),
                filled: true,
                fillColor: gold
                    ? const Color(AppColors.goldBackground)
                    : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: gold
                        ? const Color(AppColors.goldPrimary)
                        : const Color(AppColors.mainGreen),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 📚 Alphabetical list
            Expanded(
              child: BlocBuilder<AudioQuranCubit, AudioQuranStates>(
                builder: (context, state) {
                  final grouped = cubit.getGroupedReciters();

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔤 Letter Header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              entry.key,
                              style: AppTextStyles.madB14(
                                context,
                                color: gold
                                    ? const Color(AppColors.goldPrimary)
                                    : textColor.withOpacity(0.8),
                              ),
                            ),
                          ),

                          // 👳 Reciters
                          ...entry.value.map((reciter) {
                            final isSelected =
                                cubit.selectedReciter?.id == reciter.id;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (gold
                                    ? const Color(AppColors.goldPrimary)
                                    .withOpacity(0.15)
                                    : Colors.green.withOpacity(0.12))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 2,
                                ),
                                title: Text(
                                  reciter.name,
                                  style: AppTextStyles.madReg14(
                                    context,
                                    color: textColor,
                                  ),
                                ),
                                trailing: isSelected
                                    ? Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: gold
                                      ? const Color(AppColors.goldPrimary)
                                      : const Color(AppColors.mainGreen),
                                )
                                    : null,
                                onTap: () {
                                  cubit.changeReciter(reciter);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
