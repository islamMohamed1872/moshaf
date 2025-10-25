import 'package:flutter/material.dart';

import 'package:quran/quran.dart';

class HeaderWidget extends StatelessWidget {
  var e;
  var jsonData;
  final bool isDark;
  HeaderWidget(
      {super.key, required this.e, required this.jsonData, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: AlignmentGeometry.center,
        children: [
          Center(
            child: Image.asset(
              "assets/images/888-02.png",
              width: MediaQuery.of(context).size.width,
              height: 40,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.7, vertical: 7),
            child:  Center(
                child:RichText(text:  TextSpan(text:  (e["number"]-1).toString(),

                  // textAlign: TextAlign.center,
                  style:  TextStyle(
                      fontFamily: "arsura",
                      fontSize: 30,color:isDark? Colors.white:Colors.black

                  ),
                ))),

          ),
        ],
      ),
    );
  }
}
