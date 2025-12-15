import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/qiblah/qiblah_cubit.dart';
import 'package:moshaf/views/qiblah/qiblah_screen.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../widgets/header.dart';

class NewQuiblahScreen extends StatefulWidget {
  const NewQuiblahScreen({Key? key}) : super(key: key);

  @override
  State<NewQuiblahScreen> createState() => _QiblahCompassScreenState();
}

class _QiblahCompassScreenState extends State<NewQuiblahScreen>
    with WidgetsBindingObserver {

  /// 👈 FORCE calibration every time screen opens
  bool mustCalibrate = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Always start with calibration
    mustCalibrate = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FlutterQiblah().dispose();
    super.dispose();
  }

  bool _isPointingAtKaabah(double qiblahAngle) {
    final normalized = qiblahAngle.abs() % 360;
    return normalized < 30 || normalized > 330;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit c) => c.isDark);
    final gold = AppColors.isGoldMode;

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QiblahDirection>(
          stream: QiblahCubit.get(context).locationStream,
          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: gold
                      ? const Color(AppColors.goldPrimary)
                      : Colors.green,
                ),
              );
            }

            /// 👈 ALWAYS ask for calibration first
            if (mustCalibrate) {
              return Center(
                child: _buildCalibrationUI(textClr, gold),
              );
            }

            final data = snapshot.data!;
            final angle = (data.qiblah * (math.pi / 180) * -1);
            final isPointing = _isPointingAtKaabah(data.qiblah);

            return _buildCompassScreen(
              context,
              angle,
              isPointing,
              textClr,
              gold,
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CALIBRATION UI
  // ------------------------------------------------------------
  Widget _buildCalibrationUI(Color textClr, bool gold) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 160.w,
            height: 160.w,
            child: Lottie.asset(
              "assets/lotties/infinity.json",
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),

          SizedBox(height: 20.h),

          Text(
            "قم بتحريك الهاتف بهذا الشكل (∞)",
            textAlign: TextAlign.center,
            style: AppTextStyles.madB16(
              context,
              color: textClr,
            ),
          ),

          SizedBox(height: 10.h),

          Text(
            "لتحسين دقة البوصلة",
            textAlign: TextAlign.center,
            style: AppTextStyles.madReg14(
              context,
              color: textClr.withOpacity(0.7),
            ),
          ),

          SizedBox(height: 40.h),

          SizedBox(
            width: 180.w,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold
                    ? const Color(AppColors.goldPrimary)
                    : const Color(AppColors.mainGreen),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  mustCalibrate = false;
                });
              },
              child: Text(
                "تم",
                style: AppTextStyles.madB14(
                  context,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FULL COMPASS SCREEN
  // ------------------------------------------------------------
  Widget _buildCompassScreen(
      BuildContext context,
      double angle,
      bool isPointing,
      Color textClr,
      bool gold,
      ) {
    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : textClr.withOpacity(0.3);

    final bottomClr = gold
        ? const Color(AppColors.goldPrimary)
        : const Color(AppColors.mainGreen);

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: [
          Header(
            title: "تحديد القبلة",
            isDark: context.read<ThemeCubit>().isDark,
            iconColor: textClr,
          ),

          SizedBox(height: 25.h),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderClr),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 25.w, color: textClr),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    QiblahCubit.get(context).address,
                    style: AppTextStyles.madReg14(
                      context,
                      color: textClr,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),

          Expanded(
            child: Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderClr),
              ),
              child: _buildCompassUI(angle, gold, textClr),
            ),
          ),

          SizedBox(height: 30.h),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isPointing ? bottomClr : Colors.grey.shade700,
            ),
            child: Center(
              child: Text(
                isPointing ? "تم تحديد القبلة" : "تحديد القبلة",
                style: AppTextStyles.madB14(
                  context,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // COMPASS UI
  // ------------------------------------------------------------
  Widget _buildCompassUI(double angle, bool gold, Color textClr) {
    final double borderSize = 320.w;
    final double kaabahSize = 45.w;

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
          navigateTo(context, QiblahCompassScreen());
        }, icon: Icon(FontAwesomeIcons.compass))),
        Padding(
          padding: EdgeInsets.all(80.w),
          child: Image.asset(
            "assets/images/qiblah_text.png",
            width: borderSize,
            height: borderSize,
            fit: BoxFit.contain,
            color: gold
                ? const Color(AppColors.goldPrimary)
                : textClr,
          ),
        ),

        Transform.rotate(
          angle: angle,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                "assets/images/comp.png",
                width: borderSize,
                height: borderSize,
                fit: BoxFit.contain,
              ),

              Positioned(
                top: 0,
                child: Image.asset(
                  "assets/images/kaabah.png",
                  width: kaabahSize,
                  height: kaabahSize,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
