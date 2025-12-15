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

class ZekrScreen extends StatefulWidget {
  final String title;
  final Map items;

  const ZekrScreen({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  State<ZekrScreen> createState() => _ZekrScreenState();
}

class _ZekrScreenState extends State<ZekrScreen> {
  late Map<String, dynamic> _localItems;
  late String _categoryId;

  @override
  void initState() {
    super.initState();

    _localItems = {
      ...widget.items,
      'azkar': List<Map<String, dynamic>>.from(
        (widget.items['azkar'] as List)
            .map((e) => Map<String, dynamic>.from(e)),
      ),
    };

    _categoryId = _localItems['id'] ?? widget.title.replaceAll(' ', '_');
    _ensureZekrIds(_localItems['azkar'], _categoryId);
    _restoreZekrOrder(); // ✅ Load saved order on init
  }

  void _ensureZekrIds(List azkarList, String categoryId) {
    for (int i = 0; i < azkarList.length; i++) {
      final item = azkarList[i] as Map<String, dynamic>;
      item.putIfAbsent(
        'id',
            () => '${categoryId}_$i', // ✅ STABLE ID
      );
    }
  }

  /// ✅ NEW: Restore saved order
  Future<void> _restoreZekrOrder() async {
    final cubit = AzkarCubit.get(context);
    final reorderedAzkar = await cubit.loadZekrOrder(
      _categoryId,
      _localItems['azkar'] as List<Map<String, dynamic>>,
    );

    setState(() {
      _localItems['azkar'] = reorderedAzkar;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = AzkarCubit.get(context);
    final isDark = context.select((ThemeCubit c) => c.isDark);
    final gold = AppColors.isGoldMode;

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark
        ? AppColors.containerDarkBorders
        : AppColors.containerLightBorders);

    final textClr =
    gold ? const Color(AppColors.goldText) : (isDark ? Colors.white : Colors.black);

    final iconClr =
    gold ? const Color(AppColors.goldPrimary) : Color(AppColors.mainGreen);

    final azkarList = _localItems['azkar'] as List;

    return BlocBuilder<AzkarCubit, AzkarStates>(
      builder: (_, __) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                children: [
                  /// HEADER + TOGGLE
                  Row(
                    children: [
                      Expanded(
                        child: AzkarHeader(
                          title: widget.title,
                          isDark: isDark,
                          iconColor: textClr,
                          showBorder: !gold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          cubit.isSwipeView
                              ? Icons.view_list
                              : Icons.view_carousel,
                          color: textClr,
                        ),
                        onPressed: cubit.toggleViewMode,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// CONTENT
                  Expanded(
                    child: cubit.isSwipeView
                        ? _buildHorizontalView(
                        azkarList, borderClr, textClr, iconClr, gold)
                        : _buildReorderableList(
                        azkarList, cubit, borderClr, textClr, iconClr, gold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =======================
  // REORDERABLE LIST - UPDATED
  // =======================
  Widget _buildReorderableList(
      List azkarList,
      AzkarCubit cubit,
      Color borderClr,
      Color textClr,
      Color iconClr,
      bool gold,
      ) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: azkarList.length,
      onReorder: (oldIndex, newIndex) async {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = azkarList.removeAt(oldIndex);
          azkarList.insert(newIndex, item);
        });
        // ✅ SAVE order after reordering
        await cubit.saveZekrOrder(
          _categoryId,
          azkarList.cast<Map<String, dynamic>>(),
        );
      },
      itemBuilder: (context, index) {
        final item = azkarList[index];
        return Container(
          key: ValueKey(item['id']),
          margin: const EdgeInsets.only(bottom: 8),
          child: _ZekrRow(
            index: index,
            item: item,
            borderClr: borderClr,
            textClr: textClr,
            iconClr: iconClr,
            gold: gold,
            enableDrag: true,
          ),
        );
      },
    );
  }

  // =======================
  // HORIZONTAL VIEW (UNCHANGED)
  // =======================
  Widget _buildHorizontalView(
      List azkarList,
      Color borderClr,
      Color textClr,
      Color iconClr,
      bool gold,
      ) {
    final cubit = AzkarCubit.get(context);

    return PageView.builder(
      controller: cubit.pageController,
      itemCount: azkarList.length,
      onPageChanged: cubit.changeSwipeIndex,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final item = azkarList[index];

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              cubit.decrementCount(item);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['zekr'] ?? '',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.madL18(context, color: textClr),
                ),
                Row(
                  spacing: 20,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                        onTap: () {
                          cubit.pageController.previousPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Icon(Icons.arrow_back_ios_new,color: iconClr,size: 30,)),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14,horizontal: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderClr),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        spacing: 10,
                        children: [
                          GestureDetector(
                              onTap:(){
                                AzkarCubit.get(context).resetCount(item);
                              },
                              child: Icon(FontAwesomeIcons.rotateRight, size: 14, color: iconClr)),
                          Text(
                            (item['count'] ?? 0).toString().padLeft(2, '0'),
                            style: AppTextStyles.madB34(
                              context,
                              color: gold
                                  ? const Color(AppColors.goldPrimary)
                                  : Color(AppColors.mainGreen),
                            ),
                          ),
                          Text("مرات",
                              style: AppTextStyles.madReg14(context, color: textClr)),
                        ],
                      ),
                    ),
                    InkWell(
                        onTap: () {
                          cubit.pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Icon(Icons.arrow_forward_ios,color: iconClr,size: 30,)),
                  ],
                ),

              ],
            ),
          ),
        );
      },
    );
  }
}

/// =======================================================
/// ZEKR ROW (unchanged - no modifications needed)
/// =======================================================
class _ZekrRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final Color borderClr;
  final Color textClr;
  final Color iconClr;
  final bool gold;
  final bool enableDrag;

  const _ZekrRow({
    required this.index,
    required this.item,
    required this.borderClr,
    required this.textClr,
    required this.iconClr,
    required this.gold,
    required this.enableDrag,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = AzkarCubit.get(context);

    Widget content = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => cubit.decrementCount(item),
      child: _rowContent(context),
    );

    if (enableDrag) {
      content = ReorderableDelayedDragStartListener(
        index: index,
        child: content,
      );
    }

    return content;
  }

  Widget _rowContent(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Container(
            width: 75.w,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderClr),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                    onTap:(){
                      AzkarCubit.get(context).resetCount(item);
                    },
                    child: Icon(FontAwesomeIcons.rotateRight, size: 14, color: iconClr)),
                Text(
                  (item['count'] ?? 0).toString().padLeft(2, '0'),
                  style: AppTextStyles.madB34(
                    context,
                    color: gold
                        ? const Color(AppColors.goldPrimary)
                        : Color(AppColors.mainGreen),
                  ),
                ),
                Text("مرات",
                    style: AppTextStyles.madReg14(context, color: textClr)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderClr),
                color: gold ? const Color(AppColors.goldBackground) : null,
              ),
              child: Column(
                children: [
                  Text(
                    item['zekr'] ?? '',
                    style: AppTextStyles.madReg14(context, color: textClr),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

