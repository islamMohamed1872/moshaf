import 'package:flutter/material.dart';
import 'package:moshaf/constants/app_colors.dart';

class HeaderWidget extends StatelessWidget {
  final dynamic e;
  final dynamic jsonData;
  final bool isDark;

  const HeaderWidget({
    super.key,
    required this.e,
    required this.jsonData,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // GOLD MODE COLORS
    final gold = AppColors.isGoldMode;

    final textColor = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Image.asset(
              "assets/images/888-02.png",
              width: MediaQuery.of(context).size.width,
              height: 40,
              color:gold? const Color(AppColors.goldPrimary):null,
            ),
          ),

          // Surah number
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.7, vertical: 7),
            child: Center(
              child: RichText(
                text: TextSpan(
                  text: (e["number"] - 1).toString(),
                  style: TextStyle(
                    fontFamily: "arsura",
                    fontSize: 30,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
