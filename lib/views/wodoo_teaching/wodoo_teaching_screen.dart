import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/views/home/home_screen.dart';
import 'package:moshaf/views/pray_teaching/pray_instructions_screen.dart';
import 'package:moshaf/views/widgets/custom_outlined_green_button.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../widgets/custom_green_button.dart';

class WodooTeachingScreen extends StatefulWidget {
  const WodooTeachingScreen({super.key});

  @override
  State<WodooTeachingScreen> createState() => _WodooTeachingScreenState();
}

class _WodooTeachingScreenState extends State<WodooTeachingScreen> {
  int index = 0;
  List instructions = [
    {
      "title" :"غسل الكفين :",
      "content" :"تبدأ بغسل اليدين إلى الرسغين ثلاث مرات، حتى تتأكد من نظافة اليدين قبل لمس باقي الأعضاء."
    },
    {
      "title" :"المضمضة :",
      "content" :"تأخذ الماء بيدك اليمنى وتدخله في فمك، ثم تحركه داخل الفم وتخرجه، وتكرر ذلك ثلاث مرات."
    },
    {
      "title" :"الاستنشاق والاستنثار :",
      "content" :"تستنشق الماء بأنفك (تدخله للأنف قليلًا) ثم تخرجه بالنفس (الاستنثار)، وتفعل هذا ثلاث مرات."
    },
    {
      "title" :"غسل الوجه :",
      "content" :"تغسل وجهك كاملًا بالماء من منبت الشعر في الرأس حتى أسفل الذقن، ومن الأذن اليمنى إلى الأذن اليسرى، وتكرر ثلاث مرات."
    },
    {
      "title" :"غسل اليدين إلى المرفقين :",
      "content" :"تغسل اليد اليمنى من أطراف الأصابع حتى الكوع ثلاث مرات، ثم اليد اليسرى بنفس الطريقة."
    },
    {
      "title" :"مسح الرأس :",
      "content" :"تبلل يديك قليلًا ثم تمسح رأسك مرة واحدة، تبدأ من مقدمة الرأس إلى مؤخرته ثم تعود إلى الأمام مرة أخرى."
    },
    {
      "title" :"مسح الأذنين :",
      "content" :"بالماء المتبقي في يديك، تدخل السبابتين داخل الأذن وتمسح ظاهر الأذن بإبهاميك، مرة واحدة فقط."
    },
    {
      "title" :"غسل القدمين إلى الكعبين :",
      "content" :"تغسل الرجل اليمنى مع الكعبين ثلاث مرات، وتتأكد من وصول الماء بين الأصابع، ثم تفعل نفس الشيء مع الرجل اليسرى."
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("تعليم الوضوء",
                    style: AppTextStyles.madReg16(context),
                  ),
                  if(index == 0 || index == instructions.length -1)
                    InkWell(
                      onTap: () async{
                        if(index==0){
                          setState(() {
                            index = instructions.length -1;
                          });
                        }
                        else{
                          setState(() {
                            index = 0;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsetsDirectional.symmetric(
                            vertical: 6,horizontal: 19
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(38),
                          border: Border.all(
                            color: Color(AppColors.containerBorders),
                          ),
                        ),
                        child: Text(index == 0?"تخطي":"رجوع",style: AppTextStyles.madReg14(context),),
                      ),
                    ),

                ],
              ),
            ),
            SizedBox(height: 25.h,),
            Container(
              width: double.infinity,
              height: 200.h,
              padding: EdgeInsetsDirectional.only(start: 120.w,end: 120.w, top: 60.h),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(AppColors.containerBorders))),
              child: SizedBox(
                  height: 135.h,
                  child: Image.asset("assets/images/wodoo${index+1}.png")),
            ),
            const SizedBox(height: 8,),
            Container(
              width: double.infinity,
              padding: EdgeInsetsDirectional.symmetric(horizontal: 17, vertical: 12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(AppColors.containerBorders))),
              child: RichText(
                  text: TextSpan(children: [
                    TextSpan(text: "${instructions[index]["title"]}\n", style: AppTextStyles.madB14(context, color: Color(AppColors.mainGreen))),
                    TextSpan(
                        text:
                        "${instructions[index]["content"]}",
                        style: AppTextStyles.madReg14(context)),
                  ])),
            ),
            const Spacer(),
            Center(
              child: SizedBox(
                height: 8,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => index == this.index
                      ? Container(
                    width: 50,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(AppColors.mainGreen),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  )
                      : Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xff3E3E3E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemCount: 8,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            index ==0?
            CustomGreenButton(text: "التالي", onTap: () {
              if(index<7){
                setState(() {
                  index++;
                });
              }
            },):
                Row(
                  spacing: 8.w,
                  children: [
                    Expanded(child: CustomGreenButton(text:index==instructions.length-1?"تعلم الصلاة" : "التالي", onTap: () {
                      if(index == instructions.length-1){
                        navigateAndFinish(context, PrayInstructionsScreen());
                      }
                      else if(index<7){
                        setState(() {
                          index++;
                        });
                      }
                    },)),
                    Expanded(child: CustomOutlinedGreenButton(text:index==instructions.length-1?"الرجوع للرئيسية": "السابق", onTap: () {
                      if(index==instructions.length-1){
                        navigateAndFinish(context, HomeScreen());
                      }
                      else if(index>0){
                        setState(() {
                          index--;
                        });
                      }
                    },)),
                  ],
                ),
          ],
        ),
      )),
    );
  }
}
