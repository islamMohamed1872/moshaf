import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/qiblah/qiblah_cubit.dart';
import 'package:moshaf/views/home/home_screen.dart';

import '../../controllers/theme/theme_cubit.dart';
import '../widgets/header.dart';

class QiblahCompassScreen extends StatefulWidget {
  const QiblahCompassScreen({Key? key}) : super(key: key);

  @override
  State<QiblahCompassScreen> createState() => _QiblahCompassScreenState();
}

class _QiblahCompassScreenState extends State<QiblahCompassScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FlutterQiblah().dispose();
    super.dispose();
  }

  bool _isPointingAtKaabah(double qiblahAngle) {
    final normalizedAngle = qiblahAngle.abs() % 360;
    return normalizedAngle < 15 || normalizedAngle > 345;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    final gold = AppColors.isGoldMode;

    // ---- GOLD COLORS ----
    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

    final textClr =
    gold ? const Color(AppColors.goldText) : (isDark ? Colors.white : Colors.black);

    final needleOnColor = gold
        ? const Color(AppColors.goldPrimary)
        : const Color(0xff116A3E);

    final needleOffColor = gold
        ? const Color(AppColors.goldAccent)
        : const Color(0xff3E3E3E);

    final bottomBarClr = gold
        ? const Color(AppColors.goldPrimary)
        : const Color(AppColors.mainGreen);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QiblahDirection>(
          stream: QiblahCubit.get(context).locationStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: gold ? const Color(AppColors.goldPrimary) : Colors.green,
                ),
              );
            }

            if (!snapshot.hasData) {
              return Center(child: Text("جاري انتظار بيانات البوصلة...", style: TextStyle(color: textClr)));
            }

            final qiblahDirection = snapshot.data!;
            final angle = (qiblahDirection.qiblah * (math.pi / 180) * -1);
            final isPointingAtKaabah = _isPointingAtKaabah(qiblahDirection.qiblah);

            return Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  Header(
                    title: "تحديد القبلة",
                    isDark: isDark,
                    iconColor: textClr,
                    onTap: (){
                      navigateAndFinish(context, HomeScreen());
                    },
                  ),
                  SizedBox(height: 25.h),

                  // LOCATION ROW
                  Container(
                    width: double.infinity,
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderClr),
                    ),
                    child: Row(
                      spacing: 5,
                      children: [
                        Icon(Icons.location_on_outlined, size: 25.w, color: textClr),
                        Text(
                          QiblahCubit.get(context).address,
                          style: AppTextStyles.madReg14(context, color: textClr),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8),

                  // COMPASS UI
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderClr),
                      ),
                      child: _buildCompassUI(
                        angle,
                        isPointingAtKaabah,
                        needleOnColor,
                        needleOffColor,
                        textClr,
                        gold,
                      ),
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // BOTTOM STATUS BAR
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isPointingAtKaabah ? bottomBarClr : needleOffColor,
                    ),
                    child: Center(
                      child: Text(
                        isPointingAtKaabah ? "تم تحديد القبلة" : "تحديد القبلة",
                        style: AppTextStyles.madB14(context, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompassUI(
      double angle,
      bool isPointingAtKaabah,
      Color needleOn,
      Color needleOff,
      Color textClr,
      bool gold,
      ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
            top: 20,
            right: 0,
            child: IconButton(
                iconSize: 30.w,
                color: textClr,
                onPressed: (){
                  Navigator.pop(context);
                }, icon: Icon(FontAwesomeIcons.compass))),

        Positioned(top: 20.h, child: _buildDirectionText("شمال", textClr)),
        Positioned(bottom: 20.h, child: _buildDirectionText("جنوب", textClr)),
        Positioned(left: 25.w, child: _buildDirectionText("غرب", textClr)),
        Positioned(right: 25.w, child: _buildDirectionText("شرق", textClr)),

        // ROTATING NEEDLE
        Transform.rotate(
          angle: angle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 2,
                height: 200.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPointingAtKaabah
                        ? [needleOn, needleOn.withOpacity(0.7)]
                        : [needleOff, needleOff],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SizedBox(
                width: 40.w,
                height: 40.w,
                child: Image.asset("assets/images/user_pin.png",),
              ),
            ],
          ),
        ),

        // KAABA ICON
        Positioned(
          top: 90.h,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: gold
                ? const Color(AppColors.goldPrimary)
                : Colors.green.shade900,
            child: Image.asset(
              'assets/images/kaabah.png',
              width: 50,
              height: 50,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionText(String text, Color textClr) => Text(
    text,
    style: AppTextStyles.madL16(context, color: textClr.withOpacity(0.7)),
  );
}
