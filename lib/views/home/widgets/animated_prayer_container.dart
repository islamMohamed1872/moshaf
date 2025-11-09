
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_textstyles.dart';

class AnimatedPrayerContainer extends StatefulWidget {
  final bool isDark;
  final String prayerName;
  final String remainingTime;
  final String dayName;
  final String hijriDate;
  final String date;

  const AnimatedPrayerContainer({
    required this.isDark,
    required this.prayerName,
    required this.remainingTime,
    required this.dayName,
    required this.hijriDate,
    required this.date,
  });

  @override
  State<AnimatedPrayerContainer> createState() => AnimatedPrayerContainerState();
}

class AnimatedPrayerContainerState extends State<AnimatedPrayerContainer>
    with SingleTickerProviderStateMixin {
  bool _visible = true;
  bool _collapsed = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..forward();

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _collapsed = true;
          _visible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(AppColors.mainGreen);

    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: _collapsed
            ? const SizedBox.shrink()
            : FadeTransition(
          opacity: _controller.drive(Tween(begin: 0.9, end: 1.0)),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: 55.h,
                margin: EdgeInsetsDirectional.only(bottom: 20.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isDark
                        ? Color(AppColors.containerDarkBorders)
                        : Color(AppColors.containerLightBorders),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    /// Animated progress border
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ProgressBorderPainter(
                          progress: _controller.value,
                          color: color,
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 7.h, horizontal: 10.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 10.w,
                            children: [
                              Text(
                                "صلاة ${widget.prayerName} بعد",
                                style: AppTextStyles.madMd12(context,
                                    color: widget.isDark
                                        ? Colors.white
                                        : Colors.black),
                              ),
                              Text(
                                widget.remainingTime,
                                style: AppTextStyles.madMd12(context,
                                    color: widget.isDark
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ],
                          ),
                          Text(
                            "${widget.dayName} ${widget.hijriDate} - ${widget.date}",
                            style: AppTextStyles.madMd12(context,
                                color: widget.isDark
                                    ? Colors.white
                                    : Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


class _ProgressBorderPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressBorderPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );
    final totalLength = (size.width + size.height) * 2;
    final path = Path()..addRRect(rect);


    final dashLength = totalLength * progress;

    final metrics = path.computeMetrics().first;
    final extract = metrics.extractPath(0, dashLength);

    canvas.drawPath(extract, paint);
  }

  @override
  bool shouldRepaint(_ProgressBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}