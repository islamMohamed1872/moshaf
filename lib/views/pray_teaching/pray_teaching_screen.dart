import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/views/home/home_screen.dart';
import 'package:moshaf/views/pray_teaching/pray_instructions_screen.dart';
import 'package:moshaf/views/widgets/custom_outlined_green_button.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../widgets/custom_green_button.dart';

class PrayTeachingScreen extends StatefulWidget {
  const PrayTeachingScreen({super.key});

  @override
  State<PrayTeachingScreen> createState() => _PrayTeachingScreenState();
}

class _PrayTeachingScreenState extends State<PrayTeachingScreen> {
  int index = 0;
  List instructions = [
    {
      "title" :"النية والتكبير :",
      "content" : '''تستحضر النية في قلبك أنك ستصلي (مثلاً: صلاة الفجر أو الظهر...)، ثم ترفع يديك وتقول "الله أكبر".'''
    },
    {
      "title" :"قراءة الفاتحة وسورة قصيرة :",
      "content" :"تضع يدك اليمنى على اليسرى فوق صدرك، وتقرأ سورة الفاتحة، ثم تقرأ ما تيسر من القرآن بعدها."
    },
    {
      "title" :"الركوع :",
      "content" :"تكبر وتركع، واضعًا يديك على ركبتيك وظهرك مستقيم، وتقول \"سبحان ربي العظيم\" ثلاث مرات."
    },
    {
      "title" :"الرفع من الركوع :",
      "content" : '''ترفع وتقول: "سمع الله لمن حمده" ثم تقول "ربنا ولك الحمد".'''
    },
    {
      "title" :"السجود الأول :",
      "content" :'''تنزل ساجدًا على سبعة أعضاء: الجبهة والأنف، اليدين، الركبتين، وأطراف القدمين، وتقول "سبحان ربي الأعلى" ثلاث مرات.'''
    },
    {
      "title" :"الجلوس بين السجدتين :",
      "content" : '''ترفع من السجود وتجلس على رجلك اليسرى، وتقول: "رب اغفر لي، رب اغفر لي".'''
    },
    {
      "title" :"السجود الثاني :",
      "content" :"تسجد مرة أخرى مثل الأولى. (وهكذا تكون انتهيت من ركعة)."
    },
    {
      "title" :"التشهد والجلوس الأخير :",
      "content" :"في آخر ركعة تجلس وتقرأ التشهد والصلاة الإبراهيمية (التحيات لله والصلوات والطيبات، السلام عليك أيها النبي ورحمة الله وبركاته، السلام علينا وعلى عباد الله الصالحين، أشهد أن لا إله إلا الله وأشهد أن محمدًا عبده ورسوله. اللهم صلِّ على محمد وعلى آل محمد كما صليت على إبراهيم وعلى آل إبراهيم إنك حميد مجيد، اللهم بارك على محمد وعلى آل محمد كما باركت على إبراهيم وعلى آل إبراهيم إنك حميد مجيد. اللهم إني أعوذ بك من عذاب جهنم، ومن عذاب القبر، ومن فتنة المحيا والممات، ومن فتنة المسيح الدجال. السلام عليكم ورحمة الله، السلام عليكم ورحمة الله)"
    },
    {
      "title" :"التسليم :",
      "content" : '''تميل برأسك يمينًا وتقول "السلام عليكم ورحمة الله"، ثم شمالًا وتكررها، وبذلك تنتهي الصلاة.'''
    },
  ];
  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
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
                  Text("تعليم الصلاة",
                    style: AppTextStyles.madReg16(context,color: isDark?Colors.white:Colors.black),
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
                          color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders),
                        ),
                      ),
                      child: Text(index == 0?"تخطي":"رجوع",style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),),
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
                  border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders))),
              child: SizedBox(
                  height: 135.h,
                  child: Image.asset("assets/images/praying${index+1}.png")),
            ),
            const SizedBox(height: 8,),
            Container(
              width: double.infinity,
              padding: EdgeInsetsDirectional.symmetric(horizontal: 17, vertical: 12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders))),
              child: RichText(
                  text: TextSpan(children: [
                    TextSpan(text: "${instructions[index]["title"]}\n", style: AppTextStyles.madB14(context, color: Color(AppColors.mainGreen))),
                    TextSpan(
                        text: "${instructions[index]["content"]}",
                        style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black)),
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
                    decoration:  BoxDecoration(
                      color: isDark? Color(0xff3E3E3E):Color(0xffBFBFBF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemCount: instructions.length,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            index ==0||index == instructions.length-1?
            CustomGreenButton(text:index ==0? "التالي":"الذهاب للرئيسية", onTap: () {
              if(index==0){
                setState(() {
                  index++;
                });
              }
              else{
                navigateAndFinish(context, HomeScreen());
              }
            },):
                Row(
                  spacing: 8.w,
                  children: [
                    Expanded(child: CustomGreenButton(text:index==instructions.length-1?"تعلم الصلاة" : "التالي", onTap: () {
                      if(index == instructions.length-1){
                        navigateAndFinish(context, PrayInstructionsScreen());
                      }
                      else if(index<instructions.length-1){
                        setState(() {
                          index++;
                        });
                      }
                    },)),
                    Expanded(child: CustomOutlinedGreenButton(text:index==instructions.length-1?"الرجوع للرئيسية": "السابق", onTap: () {
                      if(index==instructions.length-1){
                        Navigator.pop(context);
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
