import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/controllers/settings/settings_cubit.dart';
import 'package:moshaf/controllers/settings/settings_states.dart';
import 'package:moshaf/views/widgets/header.dart';

class NotificationsControlScreen extends StatelessWidget {
  const NotificationsControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsStates>(
      builder: (context, state) {
        final cubit = SettingsCubit.get(context);
        return Scaffold(body: SafeArea(child: Column(children: [
          Header(title: "اشعارات التطبيق"),

        ])));
      },
    );
  }
}
