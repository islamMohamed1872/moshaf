import 'package:flutter/material.dart';
import 'package:moshaf/constants/app_colors.dart';

class Basmallah extends StatefulWidget {
  final int index;
  final bool isDark;

  const Basmallah({
    super.key,
    required this.index,
    required this.isDark,
  });

  @override
  State<Basmallah> createState() => _BasmallahState();
}

class _BasmallahState extends State<Basmallah> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // GOLD MODE COLOR
    final gold = AppColors.isGoldMode;
    final basmalaColor = gold
        ? const Color(AppColors.goldPrimary)
        : (widget.isDark ? Colors.white : Colors.black);

    return SizedBox(
      width: size.width,
      child: Padding(
        padding: EdgeInsets.only(
          left: size.width * .2,
          right: size.width * .2,
          top: 8,
          bottom: 2,
        ),
        child: Image.asset(
          "assets/images/Basmala.png",
          color: basmalaColor,
          width: size.width * .4,
        ),
      ),
    );
  }
}
