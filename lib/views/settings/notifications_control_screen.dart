import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/settings/settings_cubit.dart';
import 'package:moshaf/controllers/settings/settings_states.dart';
import 'package:moshaf/views/settings/widgets/custom_switch.dart';
import 'package:moshaf/views/widgets/header.dart';

import '../../controllers/theme/theme_cubit.dart';

class NotificationsControlScreen extends StatelessWidget {
  const NotificationsControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    return BlocBuilder<SettingsCubit, SettingsStates>(
      builder: (context, state) {
        final cubit = SettingsCubit.get(context);
        return Scaffold(body: SafeArea(child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(children: [
            Header(title: "اشعارات التطبيق",isDark: isDark,iconColor: isDark?Colors.white:Colors.black,),
            SizedBox(
              height: 30.h,
            ),
            Expanded(child: ListView.separated(
                itemBuilder: (context, index) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(cubit.notificationsOptions[index],
                style: AppTextStyles.madMd16(context,color: isDark?Colors.white:Colors.black),
                ),
                CustomToggleSwitch(
                  value: !cubit.isMuted(cubit.notificationsOptions[index], index),
                  onChanged: (value) {
                    cubit.muteNotification(cubit.notificationsOptions[index],context);
                  },
                )
              ],
            ),
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: 20),
                  child: Divider(),
                ),
                itemCount: cubit.notificationsOptions.length)
            )
          ]),
        )));
      },
    );
  }
}
