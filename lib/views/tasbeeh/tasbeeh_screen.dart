import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/tasbeeh/tasbeeh_cubit.dart';
import 'package:moshaf/controllers/tasbeeh/tasbeeh_states.dart';
import 'package:moshaf/views/tasbeeh/tasbeeh_animation.dart';
import 'package:moshaf/views/widgets/custom_green_button.dart';
import 'package:moshaf/views/widgets/header.dart';
import '../../controllers/theme/theme_cubit.dart';

class TasbeehScreen extends StatelessWidget {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    final gold = AppColors.isGoldMode;

    final borderColor = AppColors.getBorderColor(isDark: isDark);
    final textColor = AppColors.getTextColor(isDark: isDark);
    final primaryColor = AppColors.getPrimaryColor();
    final bgColor = AppColors.getBackgroundColor(isDark: isDark);

    return BlocProvider(
      create: (context) => TasbeehCubit()..getData(),
      child: BlocBuilder<TasbeehCubit, TasbeehStates>(
        builder: (context, state) {
          final cubit = TasbeehCubit.get(context);

          return Scaffold(
            backgroundColor: bgColor,
            body: SafeArea(
              child: GestureDetector(
                onTap: () {
                  cubit.increment();
                },
                child: Column(
                  children: [
                    Header(
                      title: "السبحة",
                      isDark: isDark,
                      iconColor: textColor,
                    ),

                    SizedBox(height: 25.h),

                    // TOTAL COUNTER
                    Container(
                      margin: EdgeInsetsDirectional.symmetric(horizontal: 15.w),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // RESET BUTTON
                          Padding(
                            padding: EdgeInsetsDirectional.symmetric(
                                horizontal: 15.w, vertical: 15.h),
                            child: IconButton(
                              onPressed: cubit.resetAll,
                              icon: Icon(
                                FontAwesomeIcons.arrowRotateRight,
                                size: 15.w,
                                color: gold
                                    ? primaryColor
                                    : textColor.withOpacity(0.8),
                              ),
                            ),
                          ),

                          Center(
                            child: Padding(
                              padding: EdgeInsetsDirectional.symmetric(
                                  vertical: 31.h),
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    bottom: 0,
                                    child: Text(
                                      cubit.totalCount
                                          .toString()
                                          .padLeft(2, "0"),
                                      style: AppTextStyles.madB85(
                                        context,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "مـــــــــــرات",
                                    style: AppTextStyles.madL40(
                                      context,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // ADD BUTTON
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: CustomGreenButton(
                        text: cubit.showInput ? "إلغاء" : "اضافة تسبيح",
                        onTap: () {
                          cubit.toggleShowInput();
                          cubit.tasbeehController.clear();
                        },
                        color: primaryColor, // gold/green auto
                      ),
                    ),

                    SizedBox(height: 10.h),

                    // INPUT FIELD
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      child: cubit.showInput
                          ? Padding(
                        key: const ValueKey("inputField"),
                        padding: EdgeInsets.symmetric(horizontal: 15.w),
                        child: Container(
                          padding: EdgeInsetsDirectional.symmetric(
                              vertical: 12.h, horizontal: 12.w),
                          height: 50.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: cubit.tasbeehController,
                                  textDirection: TextDirection.rtl,
                                  style: AppTextStyles.madB14(
                                      context,
                                      color: textColor),
                                  decoration: InputDecoration(
                                    hintText: "أدخل التسبيح الجديد...",
                                    hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13.sp),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),

                              // CHECK BUTTON
                              InkWell(
                                onTap: () {
                                  final text =
                                  cubit.tasbeehController.text.trim();
                                  if (text.isNotEmpty) {
                                    cubit.addTasbeeh(text);
                                    cubit.toggleShowInput();
                                    cubit.tasbeehController.clear();
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Icon(Icons.check,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          : null,
                    ),

                    SizedBox(height: 10.h),

                    // LIST OF TASBEEH
                    SizedBox(
                      height: 200.h,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: cubit.tasbeehList.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return Dismissible(
                            key: ValueKey(cubit.tasbeehList[index]['text']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding:
                              EdgeInsets.symmetric(horizontal: 20.w),
                              color: Colors.red.withOpacity(0.7),
                              child: const Icon(Icons.delete,
                                  color: Colors.white, size: 24),
                            ),
                            onDismissed: (_) => cubit.deleteTasbeeh(index),
                            child: InkWell(
                              onTap: () => cubit.selectTasbeeh(index),
                              child: Container(
                                width: double.infinity,
                                margin: EdgeInsetsDirectional.symmetric(
                                    horizontal: 15.w),
                                padding: EdgeInsetsDirectional.symmetric(
                                    vertical: 12.h, horizontal: 12.w),
                                decoration: BoxDecoration(
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      cubit.tasbeehList[index]['text'],
                                      style: AppTextStyles.madB14(
                                        context,
                                        color: textColor,
                                      ),
                                    ),
                                    SizedBox(width: 20.w),
                                    Text(
                                      cubit.tasbeehList[index]['count']
                                          .toString(),
                                      style: AppTextStyles.madB14(context,
                                          color: textColor),
                                    ),
                                    const Spacer(),

                                    // SELECT CIRCLE
                                    Container(
                                      width: 20.w,
                                      height: 20.w,
                                      decoration: cubit.selectedIndex == index
                                          ? BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: primaryColor,
                                      )
                                          : BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: borderColor),
                                      ),
                                      child: cubit.selectedIndex == index
                                          ? const FittedBox(
                                        child: Icon(Icons.check,
                                            color: Colors.white),
                                      )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    Expanded(child: TasbeehAnimation()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
