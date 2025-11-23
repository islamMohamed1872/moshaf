import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/constants/azkar.dart';
import 'package:moshaf/views/azkar/widgets/azkar_header.dart';
import '../../constants/app_colors.dart';

class NamesOfAllah extends StatelessWidget {
  final bool isDark;
  const NamesOfAllah({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // 🔹 GOLD MODE
    final gold = AppColors.isGoldMode;

    final borderColor = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

    final textColor = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(13.0),
          child: Column(
            children: [
              AzkarHeader(
                title: "اسماء الله الحسنى",
                isDark: isDark,
                iconColor: textColor,
              ),

              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                  itemCount: AzkarConstants.asmaaAllahAlHusna.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 12.w,
                    childAspectRatio: 2.5,
                  ),
                  itemBuilder: (context, index) {
                    final item = AzkarConstants.asmaaAllahAlHusna[index];
                    final name = item['name'].toString();
                    final meaning = item['meaning'].toString();

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      splashColor: gold
                          ? const Color(AppColors.goldPrimary).withOpacity(0.2)
                          : null,
                      highlightColor: gold
                          ? const Color(AppColors.goldPrimary).withOpacity(0.1)
                          : null,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            backgroundColor:
                            gold ? const Color(AppColors.goldBackground)
                                : isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            title: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.madL14(context).copyWith(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: gold
                                    ? const Color(AppColors.goldText)
                                    : (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                            content: Text(
                              meaning,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.madReg16(context).copyWith(
                                fontSize: 15.sp,
                                color: gold
                                    ? const Color(AppColors.goldText)
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsetsDirectional.symmetric(
                            vertical: 15, horizontal: 11),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(10),
                          color: gold
                              ? const Color(AppColors.goldBackground)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            name,
                            style: AppTextStyles.madL14(
                              context,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
