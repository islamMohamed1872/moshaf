import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/components/const.dart';
import 'package:moshaf/controllers/text_quran/text_quran_cubit.dart';
import 'package:quran/quran.dart' as quran;
// import 'package:fluttertoast/fluttertoast.dart';

Widget SoraItems(
        {required int number,
        required String arabicName,
        required String englishName,
          required context,
        required GestureTapCallback onTap}){
  return InkWell(
    onTap: onTap,
    child: Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              "assets/images/sora_number.png",
              color:  HexColor("d6bb97"),
              width: 50.w
            ),
            Text(
              TextQuranCubit.get(context).convertToArabic(number.toString()),
              style:  TextStyle(
                  color: HexColor("333333"),
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp),
            ),
          ],
        ),
        const SizedBox(
          width: 5,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              Text(
                englishName,
                style:  TextStyle(
                    color: HexColor("333333"),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold),
              ),
              Row(
                spacing: 5,
                children: [
                  Text(
                    "${quran.getVerseCount(number).toString()} ايات ",
                    textDirection: TextDirection.rtl,
                    style:  TextStyle(
                      fontFamily: "amiri",
                        color: HexColor("936f35"),
                        fontSize: 14.sp,
                        ),
                  ),
                  Text(
                      quran.getPlaceOfRevelation(
                          number) ==
                          "Makkah"
                          ? "مكية |"
                          : "مدنية |",
                    textDirection: TextDirection.rtl,
                    style:  TextStyle(
                        fontFamily: "amiri",
                        color: HexColor("936f35"),
                        fontSize: 14.sp,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          arabicName,
          style: TextStyle(
              fontFamily: "amiri",
              fontSize: 25.sp,
              color: HexColor("936f35"),
              ),
        ),
      ],
    ),
  );
}




Widget seperator() => Padding(
      padding: const EdgeInsetsDirectional.only(top: 10.0, bottom: 10.0),
      child: Container(
        width: double.infinity,
        height: 1,
        color: Colors.grey.withValues(alpha: 0.2),
      ),
    );
List<Text> list1 = [];
// Widget SoraPage({
//   required int number,
//   required int verses,
//   required soraNumber,
//   required context,
//   required GestureLongPressCallback onLongPress,
//   required cubit
// }) {
//   final mediaQuery = MediaQuery.of(context);
//   final pageData = quran.getPageData(cubit.sorahPages[cubit.pageNumber]);
//   final startVerseNumber = pageData[0]['start'];
//   return quran.getPageData(cubit.sorahPages[cubit.pageNumber]).length>1?
//   Text.rich(
//     TextSpan(
//       children: [
//         for (int i = 0; i < cubit.oneSorah().length; i++)
//           TextSpan(
//             text: cubit.oneSorah()[i],
//             recognizer: TapGestureRecognizer()
//               ..onTap = () {
//                 // AppCubit.get(context).saveLastRead(i);
//                 Fluttertoast.showToast(msg: "تم حفظ تقدمك بنجاح",
//                     toastLength: Toast.LENGTH_SHORT,
//                     backgroundColor: HexColor("d6bb97"),
//                     textColor: mainTextColor,
//                     gravity: ToastGravity.BOTTOM,
//                     fontSize: 16.0);
//               },
//             style:  TextStyle(
//               color: mainTextColor,
//               fontSize: mediaQuery.size.height/40,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//       ],
//     ),
//     textAlign: TextAlign.justify, // ✅ forces start/end to touch screen edges
//     textDirection: TextDirection.rtl,
//   ):
//   Text.rich(
//     TextSpan(
//       children: [
//         for (int i = 0; i < quran.getVersesTextByPage(cubit.sorahPages[cubit.pageNumber]).length; i++)...[
//           TextSpan(
//             text: quran.getVersesTextByPage(cubit.sorahPages[cubit.pageNumber],verseEndSymbol: false)[i],
//             recognizer: TapGestureRecognizer()
//               ..onTap = () async{
//                 // AppCubit.get(context).saveLastRead(i);
//                 Fluttertoast.showToast(msg: "تم حفظ تقدمك بنجاح",
//                     toastLength: Toast.LENGTH_SHORT,
//                     backgroundColor: HexColor("d6bb97"),
//                     textColor: mainTextColor,
//                     gravity: ToastGravity.BOTTOM,
//                     fontSize: 16.0);
//               },
//             style:  TextStyle(
//               color: mainTextColor,
//               fontSize: 16.sp,
//               fontFamily: "hafs",
//               fontWeight: FontWeight.bold,
//               height: 2
//               // fontWeight: FontWeight.bold,
//             ),
//           ),
//           WidgetSpan(
//             alignment: PlaceholderAlignment.middle,
//             child: Padding(
//               padding: const EdgeInsetsDirectional.symmetric(horizontal: 8.0),
//               child: Text(quran.getVerseEndSymbol(startVerseNumber + i),
//                 style: TextStyle(
//                   fontSize: 20,
//                 ),
//               ),
//             ),
//           ),
//         ]
//
//       ],
//     ),
//     textAlign: TextAlign.justify, // ✅ forces start/end to touch screen edges
//     textDirection: TextDirection.rtl,
//   );
// }



Widget defaultField(
    {VoidCallback? suffixPressed,
      bool isPassword = false,
      required var controller,
      required TextInputType type,
      required String label,
      ValueChanged<String>? onChanged,
      required FormFieldValidator<String> validate,
      IconData? suffix,
      ValueChanged<String>? onSubmit,
      IconData? prefix,
      context}) =>
    TextFormField(
      textAlign: TextAlign.end,
      style: const TextStyle(
        color: Colors.black,
      ),
      onFieldSubmitted: onSubmit,
      cursorColor: Colors.black,
      controller: controller,
      keyboardType: type,
      onChanged: onChanged,
      obscureText: isPassword,
      decoration: InputDecoration(
        contentPadding: EdgeInsetsDirectional.symmetric(vertical: 20),
        suffixIcon: IconButton(
          onPressed: suffixPressed,
          icon: Icon(
            suffix,
          ),
        ),
        labelText: label,
        labelStyle:  TextStyle(
          color:HexColor("333333"),
        ),
        prefixIcon: Icon(
          prefix,
          color: HexColor("333333"),
        ),
        border: InputBorder.none,
      ),
      validator: validate,
    );
Widget defaultField2(
    {VoidCallback? suffixPressed,
      bool isPassword = false,
      required var controller,
      required TextInputType type,
      required String label,
      ValueChanged<String>? onChanged,
      required FormFieldValidator<String> validate,
      IconData? suffix,
      ValueChanged<String>? onSubmit,
      IconData? prefix,
      context}) =>
    TextFormField(
      textAlign: TextAlign.start,
      style: const TextStyle(
        color: Colors.black,
      ),
      onFieldSubmitted: onSubmit,
      cursorColor: Colors.black,
      controller: controller,
      keyboardType: type,
      onChanged: onChanged,
      obscureText: isPassword,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          onPressed: suffixPressed,
          icon: Icon(
            suffix,
          ),
        ),
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: Icon(
          prefix,
          color: Colors.black,
        ),
        border: OutlineInputBorder(),
      ),
      validator: validate,
    );
void navigateTo(context, Widget) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Widget,
      ),
    );

void navigateAndFinish(context, Widget) => Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => Widget,
      ),
      (Route<dynamic> route) => false,
    );
