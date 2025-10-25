import 'package:flutter/material.dart';
import 'package:moshaf/views/azkar/widgets/azkar_header.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';

class OnePrayScreen extends StatelessWidget {
  final String title;
  final Map items;
  final bool isDark;
  const OnePrayScreen({super.key, required this.title, required this.items,required this.isDark});

  @override
  Widget build(BuildContext context) {
    final List azkarList = items["azkar"] ?? [];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AzkarHeader(title: title,isDark: isDark,),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: azkarList.length,
                separatorBuilder: (context, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = azkarList[index];
                  final benfits = item["benfits"];
                  final zekr = item["zekr"];

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sorah title (for فضل السور)
                        if (item["sorah"] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              item["sorah"],
                              style: AppTextStyles.madMd14(context,
                                  color: Color(AppColors.mainGreen)),
                            ),
                          ),
                        // zekr title
                        if(items["azkar"][index]['title']!=null&&items["azkar"][index]['title']!='')
                          Text(items["azkar"][index]['title'], style: AppTextStyles.madReg14(context,color: Color(AppColors.mainGreen))),
                        //zekr target
                        if(items["azkar"][index]['target']!=null&&items["azkar"][index]['target']!='')
                          Text(items["azkar"][index]['target'], style: AppTextStyles.madReg16(context,color: Color(AppColors.mainGreen))),

                        SizedBox(
                          height: 10,
                        ),

                        // Regular zekr (for الأذكار)
                        if (zekr != null)
                          _buildRichZekrText(context, zekr,isDark),

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
                                      style: AppTextStyles.madReg12(context,
                                          color: Color(AppColors.mainGreen)),
                                    ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  _buildRichZekrText(context, benefit["hadith"] ?? "",isDark),
                                  Divider(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders),)
                                ],
                              ),
                            );
                          }),
                  if(items["azkar"][index]['reference']!=null&&items["azkar"][index]['reference']!='')
                    Text(items["azkar"][index]['reference'], style: AppTextStyles.madReg12(context,color: Color(AppColors.mainGreen))),
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

  /// Highlight "اللَّهُمَّ" at the start of each line
  Widget _buildRichZekrText(BuildContext context, String text,bool isDark) {
    final lines = text.split('\n');

    final List<String> greenTriggers = [
      'اللَّهُمَّ',
      'قال تعالى :',
      'وقال تعالى :',
      'و قال تعالى :',
      'قال رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ:',
      'و قال رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ:',
      'أنه',
      'أن',
    ];

    return RichText(
      text: TextSpan(
        children: lines.map<InlineSpan>((line) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) return const TextSpan(text: '\n');

          // Find the first matching trigger
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
                    color: Color(AppColors.mainGreen),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: rest + '\n\n',
                  style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),
                ),
              ],
            );
          }

          // Default normal text
          return TextSpan(
            text: trimmed + '\n',
            style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),
          );
        }).toList(),
      ),
    );
  }
}
