import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/qiblah/qiblah_cubit.dart';
import 'package:permission_handler/permission_handler.dart';

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<QiblahDirection>(
          stream: QiblahCubit.get(context).locationStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.green),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: Text("جاري انتظار بيانات البوصلة..."));
            }

            final qiblahDirection = snapshot.data!;
            final angle = (qiblahDirection.qiblah * (math.pi / 180) * -1);
            final isPointingAtKaabah =
            _isPointingAtKaabah(qiblahDirection.qiblah);

            return Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  Header(title: "تحديد القبلة",isDark: isDark,),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 20,vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders)),
                    ),
                    child: Row(
                      spacing: 5,
                      children: [
                        Icon(Icons.location_on_outlined,size: 25.w,),
                        Text(QiblahCubit.get(context).address,
                          style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Expanded(child: Container(
                      width: double.infinity,
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 20,vertical: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders)),
                      ),
                      child: _buildCompassUI(angle, isPointingAtKaabah))),
                  SizedBox(
                    height: 30.h,
                  ),
                  Container(
                    width: double.infinity,
                    padding:const  EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Color(isPointingAtKaabah?AppColors.mainGreen:0xff3E3E3E),
                    ),
                    child: Center(
                      child: Text(isPointingAtKaabah?"تم تحديد القبلة":"تحديد القبلة",
                        style: AppTextStyles.madB14(context,color: isDark?Colors.white:Colors.black),
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

  Widget _buildCompassUI(double angle, bool isPointingAtKaabah) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(top: 20.h, child: _buildDirectionText("شمال")),
        Positioned(bottom: 20.h, child: _buildDirectionText("اسفل")),
        Positioned(left: 25.w, child: _buildDirectionText("يسار")),
        Positioned(right: 25.w, child: _buildDirectionText("يمين")),
        Transform.rotate(
          angle: angle,
          origin: Offset.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 2,
                height: 200.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPointingAtKaabah
                        ? [Color(0xff116A3E), Color(0xff17472F)]
                        : [Color(0xff3E3E3E), Color(0xff3E3E3E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SizedBox(
                width: 40.w,
                height: 40.w,
                child: Image.asset("assets/images/user_pin.png"),
              ),
            ],
          ),
        ),
        Positioned(
          top: 90.h,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.green.shade900,
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

  Widget _buildDirectionText(String text) => Text(
    text,
    style: AppTextStyles.madL16(context,color: Color(0xff3E3E3E)),
  );
}