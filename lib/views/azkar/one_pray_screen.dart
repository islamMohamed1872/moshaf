import 'package:flutter/material.dart';
import 'package:moshaf/views/azkar/widgets/azkar_header.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';

class OnePrayScreen extends StatelessWidget {
  final String title;
  final Map items;
  final bool isDark;

  const OnePrayScreen({
    super.key,
    required this.title,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final List azkarList = items["azkar"] ?? [];

    // 🔹 GOLD MODE
    final gold = AppColors.isGoldMode;

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

    final zekrColor = gold
        ? const Color(AppColors.goldPrimary)
        : Color(AppColors.mainGreen);

    final textColor = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final referenceColor = gold
        ? const Color(AppColors.goldPrimary)
        : Color(AppColors.mainGreen);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AzkarHeader(
              title: title,
              isDark: isDark,
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: azkarList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = azkarList[index];
                  final benfits = item["benfits"];
                  final zekr = item["zekr"];

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderClr),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // سورah title (only in فضل السور)
                        if (item["sorah"] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              item["sorah"],
                              style: AppTextStyles.madMd14(
                                context,
                                color: zekrColor,
                              ),
                            ),
                          ),

                        // Title
                        if (item['title'] != null && item['title'] != '')
                          Text(
                            item['title'],
                            style: AppTextStyles.madReg14(
                              context,
                              color: zekrColor,
                            ),
                          ),

                        // Target
                        if (item['target'] != null && item['target'] != '')
                          Text(
                            item['target'],
                            style: AppTextStyles.madReg16(
                              context,
                              color: zekrColor,
                            ),
                          ),

                        const SizedBox(height: 10),

                        // Zekr text
                        if (zekr != null)
                          _buildRichZekrText(context, zekr, isDark, gold),

                        // Benefits (فضائل)
                        if (benfits != null)
                          ...benfits.map<Widget>((benefit) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (benefit["reference"] != null)
                                    Text(
                                      benefit["reference"],
                                      style: AppTextStyles.madReg12(
                                        context,
                                        color: referenceColor,
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  _buildRichZekrText(
                                      context,
                                      benefit["hadith"] ?? "",
                                      isDark,
                                      gold),
                                  Divider(
                                    color: borderClr,
                                  )
                                ],
                              ),
                            );
                          }),

                        // Reference (normal azkar)
                        if (item['reference'] != null &&
                            item['reference'] != '')
                          Text(
                            item['reference'],
                            style: AppTextStyles.madReg12(
                              context,
                              color: referenceColor,
                            ),
                          ),
                      ],
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

  /// Highlight special words and support GOLD MODE
  Widget _buildRichZekrText(
      BuildContext context, String text, bool isDark, bool gold) {
    final lines = text.split('\n');

    final greenTriggers = [
      'اللَّهُمَّ',
      'قال تعالى :',
      'وقال تعالى :',
      'و قال تعالى :',
      'قال رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ:',
      'و قال رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ:',
      'أنه',
      'أن',
    ];

    final highlightColor =
    gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen);

    final normalTextColor =
    gold ? const Color(AppColors.goldText) : (isDark ? Colors.white : Colors.black);

    return RichText(
      text: TextSpan(
        children: lines.map<InlineSpan>((line) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) return const TextSpan(text: '\n');

          final match = greenTriggers.firstWhere(
                (trigger) => trimmed.startsWith(trigger),
            orElse: () => '',
          );

          if (match.isNotEmpty) {
            final rest = trimmed.substring(match.length);
            return TextSpan(
              children: [
                TextSpan(
                  text: match,
                  style: AppTextStyles.madReg14(context).copyWith(
                    color: highlightColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: rest + '\n\n',
                  style: AppTextStyles.madReg14(
                    context,
                    color: normalTextColor,
                  ),
                ),
              ],
            );
          }

          return TextSpan(
            text: trimmed + '\n',
            style: AppTextStyles.madReg14(
              context,
              color: normalTextColor,
            ),
          );
        }).toList(),
      ),
    );
  }
}
