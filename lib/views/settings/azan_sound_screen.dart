// ── azan_sound_screen.dart ───────────────────────────────────────────────────
// What's new vs original:
//   • "إضافة أذان مخصص" button → calls cubit.addCustomSound()
//   • Custom sounds section rendered below the dropdown with delete chips
//   • Demo notification fires automatically on every sound change
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/controllers/settings/settings_cubit.dart';
import 'package:moshaf/controllers/settings/settings_states.dart';
import 'package:moshaf/views/widgets/header.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';

class AzanSoundScreen extends StatelessWidget {
  const AzanSoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark      = context.select((ThemeCubit c) => c.isDark);
    final textColor   = AppColors.getTextColor(isDark: isDark);
    final borderColor = AppColors.getBorderColor(isDark: isDark);
    final bgColor     = AppColors.getBackgroundColor(isDark: isDark);
    final primaryClr  = AppColors.getPrimaryColor();

    return BlocBuilder<SettingsCubit, SettingsStates>(
      builder: (context, state) {
        final cubit = SettingsCubit.get(context);

        return Scaffold(
          backgroundColor: bgColor,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ──────────────────────────────────────────
                  Header(title: "صوت الآذان", isDark: isDark, iconColor: textColor),

                  SizedBox(height: 28.h),

                  // ── Sound dropdown ───────────────────────────────────
                  Text("اختر المؤذن",
                      style: AppTextStyles.madReg14(context, color: textColor)),

                  SizedBox(height: 10.h),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: cubit.azanSound,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: textColor),
                        dropdownColor: bgColor,
                        borderRadius: BorderRadius.circular(12.r),
                        items: cubit.azanSoundList.map((name) {
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Row(children: [
                              Expanded(
                                child: Text(name,
                                    style: AppTextStyles.madReg12(context,
                                        color: textColor)),
                              ),
                              // Show delete icon only for custom sounds
                              if (cubit.customSounds
                                  .any((e) => e['name'] == name))
                                GestureDetector(
                                  // Prevent the dropdown from selecting on tap
                                  onTap: () async {
                                    // Close dropdown first
                                    Navigator.pop(context);
                                    await cubit.removeCustomSound(
                                        name, context);
                                  },
                                  child: Icon(Icons.delete_outline_rounded,
                                      size: 18.sp,
                                      color: Colors.redAccent),
                                ),
                            ]),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            cubit.changeAzanSound(value, context);
                          }
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Demo hint
                  Row(children: [
                    Icon(Icons.info_outline_rounded,
                        size: 13.sp,
                        color: textColor.withOpacity(0.45)),
                    SizedBox(width: 5.w),
                    Text(
                      "سيصلك إشعار تجريبي عند تغيير الصوت",
                      style: AppTextStyles.madReg10(context,
                          color: textColor.withOpacity(0.45)),
                    ),
                  ]),

                  SizedBox(height: 28.h),

                  // ── Custom sounds section ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("أصوات مخصصة",
                          style: AppTextStyles.madReg14(context,
                              color: textColor)),
                      Text("${cubit.customSounds.length} مضاف",
                          style: AppTextStyles.madReg12(context,
                              color: textColor.withOpacity(0.45))),
                    ],
                  ),

                  SizedBox(height: 10.h),

                  // Custom sound chips
                  if (cubit.customSounds.isNotEmpty)
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: cubit.customSounds.map((entry) {
                        final name = entry['name']!;
                        final isSelected = cubit.azanSound == name;
                        return GestureDetector(
                          onTap: () => cubit.changeAzanSound(name, context),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: isSelected
                                  ? primaryClr.withOpacity(0.12)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? primaryClr : borderColor,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  Padding(
                                    padding: EdgeInsets.only(left: 6.w),
                                    child: Icon(Icons.volume_up_rounded,
                                        size: 13.sp, color: primaryClr),
                                  ),
                                Text(name,
                                    style: AppTextStyles.madReg12(context,
                                        color: isSelected
                                            ? primaryClr
                                            : textColor)),
                                SizedBox(width: 8.w),
                                GestureDetector(
                                  onTap: () =>
                                      cubit.removeCustomSound(name, context),
                                  child: Icon(Icons.close_rounded,
                                      size: 14.sp,
                                      color: textColor.withOpacity(0.5)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 18.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                            color: borderColor,
                            style: BorderStyle.solid),
                      ),
                      child: Column(children: [
                        Icon(Icons.audio_file_outlined,
                            size: 28.sp,
                            color: textColor.withOpacity(0.3)),
                        SizedBox(height: 6.h),
                        Text(
                          "لم تضف أي أصوات بعد",
                          style: AppTextStyles.madReg12(context,
                              color: textColor.withOpacity(0.45)),
                          textAlign: TextAlign.center,
                        ),
                      ]),
                    ),

                  SizedBox(height: 20.h),

                  // ── Add custom sound button ───────────────────────────
                  GestureDetector(
                    onTap: () => cubit.addCustomSound(context),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color: primaryClr.withOpacity(0.08),
                        border: Border.all(
                            color: primaryClr.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              color: primaryClr, size: 18.sp),
                          SizedBox(width: 8.w),
                          Text(
                            "إضافة أذان من الهاتف",
                            style: AppTextStyles.madReg14(context,
                                color: primaryClr),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}