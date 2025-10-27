import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/azkar/azkar_cubit.dart';
import 'package:moshaf/controllers/azkar/azkar_states.dart';
import 'package:moshaf/views/azkar/widgets/azkar_header.dart';

import '../../constants/app_colors.dart';
import '../../controllers/theme/theme_cubit.dart';

class ZekrScreen extends StatelessWidget {
  final String title;
  final Map items;
  const ZekrScreen({super.key,required this.title,required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    return BlocBuilder<AzkarCubit,AzkarStates>(
      builder: (context, state) {
        final cubit = AzkarCubit.get(context);
        return  Scaffold(
          body: SafeArea(child: Padding(
            padding: const EdgeInsets.all(13.0),
            child: Column(
              children: [
                AzkarHeader(title: title,isDark: isDark,),
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (context, index) => IntrinsicHeight(
                      child: Row(
                        spacing: 4,
                        children: [
                          InkWell(
                            onTap: () {
                              cubit.decrementCount(items["azkar"][index]);
                            },
                            child: Container(
                              width: 75.w,
                              padding: EdgeInsetsDirectional.symmetric(vertical: 9, horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                spacing: 10,
                                children: [
                                  InkWell(
                                      onTap: () {
                                        cubit.resetCount(items["azkar"][index]);
                                      },
                                      child: SizedBox(
                                          width: 20.w,
                                          height: 20.w,
                                          child: Icon(FontAwesomeIcons.rotateRight,color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders),size: 12,))),
                                  Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        items["azkar"][index]['count'].toString().padLeft(2, "0"),
                                        style: AppTextStyles.madB34(
                                          context,
                                          color: Color(AppColors.mainGreen),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text("مرات",
                                      style: AppTextStyles.madReg16(context,color: isDark?Colors.white:Colors.black),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsetsDirectional.symmetric(vertical: 10, horizontal: 15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders)),
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  spacing: 10,
                                  children: [
                                    if(items["azkar"][index]['title']!=null)
                                      Text(items["azkar"][index]['title'],
                                        style: AppTextStyles.madReg12(context,color: Color(AppColors.mainGreen)),
                                      ),
                                    Text(items["azkar"][index]['zekr'],
                                      style: AppTextStyles.madReg14(context,color: isDark?Colors.white:Colors.black),
                                    ),
                                    if(items["azkar"][index]['reference']!=null)
                                    Text(items["azkar"][index]['reference'],
                                      style: AppTextStyles.madReg12(context,color: Color(AppColors.mainGreen)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    separatorBuilder: (context, index) => SizedBox(height: 8,),
                    itemCount: items["azkar"].length,
                  ),
                )
              ],
            ),
          )),
        );
      },
    );
  }
}
