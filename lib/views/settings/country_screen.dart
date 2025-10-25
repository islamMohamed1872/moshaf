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
    return BlocBuilder<SettingsCubit,SettingsStates>(
        builder: (context, state) {
          final cubit = SettingsCubit.get(context);
          return Scaffold(
            resizeToAvoidBottomInset: true,
            body: SafeArea(child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Header(title: "البلد",isDark: isDark,iconColor: isDark?Colors.white:Colors.black,),
                SizedBox(height:  35.h),
                Text("الدولة",
                style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),
                ),
                const SizedBox(height:  15),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric( horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text(
                        'اختر الدولة',
                        style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),
                      ),
                      value: cubit.country,
                      icon: Icon(Icons.keyboard_arrow_down_rounded),
                      dropdownColor: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders),
                      borderRadius: BorderRadius.circular(12.r),
                      items: cubit.countries.map((String name) {
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(
                            name,
                            style: AppTextStyles.madReg12(context,color: isDark?Colors.white:Colors.black),
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
            )
            ),
          );
        },
    );
  }
}
