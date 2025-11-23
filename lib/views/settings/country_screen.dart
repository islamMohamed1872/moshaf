import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/controllers/settings/settings_cubit.dart';
import 'package:moshaf/controllers/settings/settings_states.dart';
import 'package:moshaf/views/widgets/header.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';

class CountryScreen extends StatelessWidget {
  const CountryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);

    final textColor = AppColors.getTextColor(isDark: isDark);
    final borderColor = AppColors.getBorderColor(isDark: isDark);
    final bgColor = AppColors.getBackgroundColor(isDark: isDark);

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
                  Header(
                    title: "البلد",
                    isDark: isDark,
                    iconColor: textColor,
                  ),

                  SizedBox(height: 35.h),

                  Text(
                    "الدولة",
                    style: AppTextStyles.madReg14(context, color: textColor),
                  ),

                  const SizedBox(height: 15),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: cubit.country,
                        hint: Text(
                          "اختر الدولة",
                          style: AppTextStyles.madReg14(context, color: textColor),
                        ),
                        dropdownColor: bgColor,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: textColor,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        items: cubit.countries.map((String name) {
                          return DropdownMenuItem(
                            value: name,
                            child: Text(
                              name,
                              style: AppTextStyles.madReg12(
                                context,
                                color: textColor,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          cubit.changeCountry(newValue!);
                        },
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
