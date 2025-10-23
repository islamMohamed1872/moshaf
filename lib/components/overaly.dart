import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/controllers/home/home_cubit.dart';
import 'package:moshaf/cubit/cubit.dart';
import 'package:moshaf/cubit/states.dart';
import 'package:moshaf/views/home/home_screen.dart';

import 'const.dart';

class OverlayAthkarWidget extends StatelessWidget {
  const OverlayAthkarWidget({super.key});



  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit,AppStates>(
      builder: (context, state) {
        final cubit = HomeCubit.get(context);
        if(state is !GetRandomAthkarState) cubit.getRandomAthkar();
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HexColor("#f3eee7"),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                cubit.athkar,
                style: TextStyle(
                  color: mainTextColor,
                  fontSize: 17,
                  fontFamily: "nabi",
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
