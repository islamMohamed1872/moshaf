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
  const ZekrScreen({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);

    // GOLD MODE
    final gold = AppColors.isGoldMode;

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final textClr = gold ? const Color(AppColors.goldText) : (isDark ? Colors.white : Colors.black);

    final iconClr = gold
        ? const Color(AppColors.goldPrimary)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    return BlocBuilder<AzkarCubit, AzkarStates>(
      builder: (context, state) {
        final cubit = AzkarCubit.get(context);

        // safe fallback if cubit doesn't expose isSwipeView
        final bool isSwipeView = (cubit.isSwipeView is bool) ? cubit.isSwipeView : false;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(13.0),
              child: Column(
                children: [
                  // Header + toggle button row
                  Row(
                    children: [
                      Expanded(
                        child: AzkarHeader(
                          title: title,
                          isDark: isDark,
                          iconColor: textClr,
                          showBorder: !gold,
                        ),
                      ),

                      // toggle view button
                      IconButton(
                        tooltip: isSwipeView ? 'List view' : 'Swipe view',
                        onPressed: () {
                          // toggle in cubit (expect method exists)
                          try {
                            cubit.toggleViewMode();
                          } catch (_) {}
                        },
                        icon: Icon(
                          isSwipeView ? Icons.view_list : Icons.view_carousel,
                          color: textClr,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // content: either list view or swipe view
                  Expanded(
                    child: isSwipeView
                        ? _buildSwipeView(context, items, gold, borderClr, textClr, iconClr)
                        : _buildListView(context, items, gold, borderClr, textClr, iconClr),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  //---------------------------------------
  // List view builder & row builder
  //---------------------------------------
  Widget _buildListView(
      BuildContext context,
      Map items,
      bool gold,
      Color borderClr,
      Color textClr,
      Color iconClr,
      ) {
    final azkarList = (items['azkar'] as List?) ?? [];

    return ListView.separated(
      itemCount: azkarList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = azkarList[index] as Map<String, dynamic>;
        return _buildZekrRow(context, item, gold, borderClr, textClr, iconClr);
      },
    );
  }

  Widget _buildZekrRow(
      BuildContext context,
      Map<String, dynamic> item,
      bool gold,
      Color borderClr,
      Color textClr,
      Color iconClr,
      ) {
    final cubit = AzkarCubit.get(context);

    return IntrinsicHeight(
      child: InkWell(
        onTap: () {
          cubit.decrementCount(item);
        },
        child: Row(
          children: [
            // COUNTER BOX
            Container(
              width: 75.w,
              padding: EdgeInsetsDirectional.symmetric(vertical: 9, horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderClr),
                color: gold ? const Color(AppColors.goldBackground) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => cubit.resetCount(item),
                    child: SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: Icon(
                        FontAwesomeIcons.rotateRight,
                        color: iconClr,
                        size: 12,
                      ),
                    ),
                  ),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      (item['count'] ?? 0).toString().padLeft(2, "0"),
                      style: AppTextStyles.madB34(
                        context,
                        color: gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  Text(
                    "مرات",
                    style: AppTextStyles.madReg16(context, color: textClr),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ZEKR CONTENT BOX
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsetsDirectional.symmetric(vertical: 10, horizontal: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderClr),
                  color: gold ? const Color(AppColors.goldBackground) : null,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item['title'] != null)
                        Text(
                          item['title'] ?? '',
                          style: AppTextStyles.madReg12(
                            context,
                            color: gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen),
                          ),
                        ),

                      const SizedBox(height: 6),

                      Text(
                        item['zekr'] ?? '',
                        style: AppTextStyles.madReg14(context, color: textClr),
                      ),

                      if (item['reference'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            item['reference'] ?? '',
                            style: AppTextStyles.madReg12(
                              context,
                              color: gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //---------------------------------------
  // Swipe (single zekr) view — optimized & adaptive
  //---------------------------------------
  Widget _buildSwipeView(
      BuildContext context,
      Map items,
      bool gold,
      Color borderClr,
      Color textClr,
      Color iconClr,
      ) {
    final cubit = AzkarCubit.get(context);
    final azkarList = (items['azkar'] as List?) ?? [];

    // use cubit's controller if available, otherwise create a local one
    final PageController controller = (cubit.pageController is PageController) ? cubit.pageController : PageController(initialPage: 0);

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: controller,
            itemCount: azkarList.length,
            onPageChanged: (index) {
              cubit.changeSwipeIndex(index);
            },
            itemBuilder: (context, index) {
              final item = azkarList[index] as Map<String, dynamic>;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                child: Column(
                  children: [
                    // Title (optional)
                    if ((item['title'] as String?)?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          item['title'] ?? '',
                          style: AppTextStyles.madReg16(context, color: gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen)),
                        ),
                      ),

                    Expanded(
                      child: SingleChildScrollView(
                        child: GestureDetector(
                          onTap: () => cubit.decrementCount(item),
                          child: Center(
                            child: Text(
                              item['zekr'] ?? '',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.madReg20(context, color: textClr),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // counter + actions (adaptive)
                    LayoutBuilder(builder: (context, constraints) {
                      // available width
                      final maxW = constraints.maxWidth;
                      // desired counter width, but clamp to available space
                      final counterWidth = (maxW * 0.45).clamp(110.0, 180.0);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // counter box (flexible width)
                          IconButton(
                            onPressed: () {
                              final prev = (index - 1) < 0 ? azkarList.length - 1 : index - 1;
                              controller.animateToPage(prev, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                              cubit.changeSwipeIndex(prev);
                            },
                            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textClr),
                          ),
                          GestureDetector(
                            onTap: () => cubit.decrementCount(item),
                            onLongPress: () => cubit.resetCount(item),
                            child: Container(
                              width: counterWidth.w,
                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderClr),
                                color: gold ? const Color(AppColors.goldBackground) : null,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    (item['count'] ?? 0).toString().padLeft(2, '0'),
                                    style: AppTextStyles.madB34(
                                      context,
                                      color: gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen),
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text("اضغط للتنقيص", style: AppTextStyles.madReg12(context, color: textClr)),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              final next = (index + 1) % azkarList.length;
                              controller.animateToPage(next, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                              cubit.changeSwipeIndex(next);
                            },
                            icon: Icon(Icons.arrow_forward_ios, color: textClr),
                          ),

                        ],
                      );
                    }),

                    SizedBox(height: 12.h),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(BuildContext context, int itemCount, int current, Color activeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (i) {
        final bool active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? activeColor : activeColor.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
