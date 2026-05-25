import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';
import 'package:moshaf/views/azkar/one_pray_screen.dart';
import 'package:moshaf/views/widgets/header.dart';

import '../../controllers/hadith/hadith_cubit.dart';
import '../../controllers/hadith/hadith_states.dart';
import '../../services/hadith_service.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Local search state — lives in the widget, not the cubit
  bool _isSearching = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = HadithCubit.get(context);
      if (cubit.hadithMap.isEmpty) {
        cubit.loadBook(cubit.selectedEdition);
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }


  String _removeTashkeel(String text) {
    // Unicode range for Arabic diacritics (tashkeel): U+0610 – U+061A and U+064B – U+065F
    return text.replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F]'), '');
  }

  // ── Search logic ──────────────────────────────────────────

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        print("empty");
        _searchResults = [];
      } else {
        print("not empty");
        _runSearch(query);
      }
    });
  }

  void _runSearch(String query) {
    final cubit       = HadithCubit.get(context);
    final allHadiths  = cubit.allHadiths;
    final cleanQuery  = _removeTashkeel(query).toLowerCase();   // ← strip from query

    _searchResults = allHadiths
        .whereType<Map<String, dynamic>>()
        .where((h) {
      final zekr      = _removeTashkeel(h['zekr']      as String? ?? '').toLowerCase(); // ← strip from text
      final reference = _removeTashkeel(h['reference'] as String? ?? '').toLowerCase();
      return zekr.contains(cleanQuery) || reference.contains(cleanQuery);
    })
        .toList();
  }
  void _openSearch() {
    setState(() => _isSearching = true);
    _searchFocus.requestFocus();
  }

  void _closeSearch() {
    setState(() {
      _isSearching  = false;
      _searchQuery  = '';
      _searchResults = [];
    });
    _searchController.clear();
    _searchFocus.unfocus();
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark   = context.select((ThemeCubit c) => c.isDark);
    final gold     = AppColors.isGoldMode;

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(isDark ? AppColors.containerDarkBorders : AppColors.containerLightBorders);

    final textClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white : Colors.black);

    final accentClr = gold
        ? const Color(AppColors.goldPrimary)
        : Color(AppColors.mainGreen);

    final bgClr = gold
        ? const Color(AppColors.goldBackground)
        : (isDark ? const Color(0xFF151515) : Colors.white);

    return BlocBuilder<HadithCubit, HadithStates>(
      builder: (context, state) {
        final cubit = HadithCubit.get(context);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [

                // ── Header ──────────────────────────────────
                _isSearching
                    ? _buildSearchBar(context, borderClr, textClr, accentClr, bgClr)
                    : _buildHeader(context, isDark, gold, accentClr, bgClr),

                // ── Divider ──────────────────────────────────
                Container(
                  height: 1,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: borderClr,
                ),

                // ── Book selector (hidden while searching) ───
                if (!_isSearching) ...[
                  _buildBookSelector(context, cubit, borderClr, textClr, accentClr),
                  SizedBox(height: 10.h),
                ],

                // ── Body ─────────────────────────────────────
                Expanded(
                  child: _isSearching && _searchQuery.isNotEmpty
                      ? _buildSearchResults(context, cubit, isDark, borderClr, textClr, accentClr)
                      : _buildBody(context, cubit, state, isDark, borderClr, textClr, accentClr),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header (normal mode) ──────────────────────────────────

  Widget _buildHeader(
      BuildContext context,
      bool isDark,
      bool gold,
      Color accentClr,
      Color bgClr,
      ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          "assets/images/prays_bg.png",
          height: 160.h,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Container(
          width: double.infinity,
          height: 160.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0), bgClr],
            ),
          ),
        ),
        Positioned(
          top: 15, right: 0, left: 0,
          child: Row(
            children: [
              Expanded(
                child: Header(
                  title: "الأحاديث النبوية",
                  onTap: () => Navigator.pop(context),
                  isDark: isDark,
                  iconColor: gold ? const Color(AppColors.goldAccent) : null,
                ),
              ),
              // Search icon
              GestureDetector(
                onTap: _openSearch,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: 16.w),
                  child: Icon(
                    Icons.search_rounded,
                    color: gold
                        ? const Color(AppColors.goldAccent)
                        : (isDark ? Colors.white : Colors.black),
                    size: 24.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          child: Text(
            "اقرأ وتدبّر",
            style: AppTextStyles.kufi24(
              context,
              color: gold ? const Color(AppColors.goldAccent) : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ── Search bar (replaces header while searching) ──────────

  Widget _buildSearchBar(
      BuildContext context,
      Color borderClr,
      Color textClr,
      Color accentClr,
      Color bgClr,
      ) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      color: bgClr,
      child: Row(
        children: [
          // Close search
          GestureDetector(
            onTap: _closeSearch,
            child: Icon(Icons.arrow_forward_rounded, color: accentClr, size: 22.sp),
          ),
          SizedBox(width: 10.w),

          // Text field
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderClr),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.madReg14(context, color: textClr),
                decoration: InputDecoration(
                  hintText: "ابحث في الأحاديث...",
                  hintStyle: AppTextStyles.madReg14(
                    context,
                    color: textClr.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery   = '';
                        _searchResults = [];
                      });
                    },
                    child: Icon(Icons.close_rounded,
                        color: accentClr, size: 18.sp),
                  )
                      : Icon(Icons.search_rounded,
                      color: textClr.withValues(alpha: 0.4), size: 18.sp),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Book chips ────────────────────────────────────────────

  Widget _buildBookSelector(
      BuildContext context,
      HadithCubit cubit,
      Color borderClr,
      Color textClr,
      Color accentClr,
      ) {
    return SizedBox(
      height: 38.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        children: kHadithBooks.entries.map((entry) {
          final isSelected = cubit.selectedEdition == entry.key;
          return GestureDetector(
            onTap: () {
              _closeSearch();
              cubit.changeBook(entry.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(left: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? accentClr : borderClr,
                  width: isSelected ? 1.5 : 1,
                ),
                color: isSelected
                    ? accentClr.withValues(alpha: 0.08)
                    : Colors.transparent,
              ),
              child: Text(
                entry.value,
                style: AppTextStyles.madMd12(
                  context,
                  color: isSelected ? accentClr : textClr,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Search results ────────────────────────────────────────

  Widget _buildSearchResults(
      BuildContext context,
      HadithCubit cubit,
      bool isDark,
      Color borderClr,
      Color textClr,
      Color accentClr,
      ) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: accentClr.withValues(alpha: 0.4)),
            SizedBox(height: 12.h),
            Text(
              "لا توجد نتائج لـ \"$_searchQuery\"",
              style: AppTextStyles.madReg14(context, color: textClr),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          child: Row(
            children: [
              Text(
                "${_searchResults.length} نتيجة في ${cubit.selectedBookName}",
                style: AppTextStyles.madReg12(context, color: accentClr),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            itemCount: _searchResults.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final item = _searchResults[index];
              return _hadithCard(
                context,
                item: item,
                displayNumber: item['reference'] as String? ?? '',
                isDark: isDark,
                borderClr: borderClr,
                textClr: textClr,
                accentClr: accentClr,
                cubit: cubit,
                highlightQuery: _searchQuery,
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Normal paginated list ─────────────────────────────────

  Widget _buildBody(
      BuildContext context,
      HadithCubit cubit,
      HadithStates state,
      bool isDark,
      Color borderClr,
      Color textClr,
      Color accentClr,
      ) {
    if (state is HadithLoadingState || cubit.isLoading) {
      return Center(child: CircularProgressIndicator(color: accentClr));
    }

    if (state is HadithErrorState || cubit.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: accentClr),
            SizedBox(height: 12.h),
            Text(
              "تعذّر تحميل الأحاديث\nتحقق من اتصالك بالإنترنت",
              textAlign: TextAlign.center,
              style: AppTextStyles.madReg14(context, color: textClr),
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () => cubit.loadBook(cubit.selectedEdition),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentClr),
                ),
                child: Text(
                  "إعادة المحاولة",
                  style: AppTextStyles.madMd14(context, color: accentClr),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (cubit.hadithMap.isEmpty) {
      return Center(
        child: Text(
          "اختر كتاباً لعرض الأحاديث",
          style: AppTextStyles.madReg14(context, color: textClr),
        ),
      );
    }

    final pageItems = cubit.currentPageItems;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${cubit.selectedBookName}  ·  ${cubit.allHadiths.length} حديث",
                style: AppTextStyles.madReg12(context, color: textClr),
              ),
              Text(
                "صفحة ${cubit.currentPage + 1} / ${cubit.totalPages}",
                style: AppTextStyles.madReg12(context, color: accentClr),
              ),
            ],
          ),
        ),

        SizedBox(height: 6.h),

        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            itemCount: pageItems.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final item = pageItems[index] as Map<String, dynamic>;
              final number = (cubit.currentPage * HadithCubit.pageSize) + index + 1;
              return _hadithCard(
                context,
                item: item,
                displayNumber: "$number",
                isDark: isDark,
                borderClr: borderClr,
                textClr: textClr,
                accentClr: accentClr,
                cubit: cubit,
              );
            },
          ),
        ),

        _buildPaginationBar(context, cubit, borderClr, textClr, accentClr),
      ],
    );
  }

  // ── Shared hadith card ────────────────────────────────────

  Widget _hadithCard(
      BuildContext context, {
        required Map<String, dynamic> item,
        required String displayNumber,
        required bool isDark,
        required Color borderClr,
        required Color textClr,
        required Color accentClr,
        required HadithCubit cubit,
        String? highlightQuery,
      }) {
    final zekrText = item['zekr'] as String? ?? '';

    return GestureDetector(
      onTap: () => navigateTo(
        context,
        OnePrayScreen(
          title: cubit.selectedBookName,
          items: {
            "category": cubit.selectedBookName,
            "azkar": [item],
          },
          // isDark: isDark,
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderClr),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number / badge
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentClr.withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: Text(
                displayNumber,
                style: AppTextStyles.madReg12(context, color: accentClr),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 10.w),

            // Text
            Expanded(
              child: highlightQuery != null && highlightQuery.isNotEmpty
                  ? _highlightedText(context, zekrText, highlightQuery, textClr, accentClr)
                  : Text(
                zekrText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.madReg14(context, color: textClr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Highlight matched text ────────────────────────────────

  Widget _highlightedText(
      BuildContext context,
      String text,
      String query,
      Color textClr,
      Color accentClr,
      ) {
    final lowerText  = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans      = <TextSpan>[];

    int start = 0;
    int idx   = lowerText.indexOf(lowerQuery, start);

    while (idx != -1) {
      // Normal text before match
      if (idx > start) {
        spans.add(TextSpan(
          text: text.substring(start, idx),
          style: AppTextStyles.madReg14(context, color: textClr),
        ));
      }
      // Highlighted match
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: AppTextStyles.madReg14(context, color: accentClr).copyWith(
          fontWeight: FontWeight.bold,
          backgroundColor: accentClr.withValues(alpha: 0.12),
        ),
      ));
      start = idx + query.length;
      idx   = lowerText.indexOf(lowerQuery, start);
    }

    // Remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: AppTextStyles.madReg14(context, color: textClr),
      ));
    }

    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  // ── Pagination bar ────────────────────────────────────────

  Widget _buildPaginationBar(
      BuildContext context,
      HadithCubit cubit,
      Color borderClr,
      Color textClr,
      Color accentClr,
      ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _pageBtn(context,
              label: "السابق",
              enabled: cubit.currentPage > 0,
              onTap: cubit.prevPage,
              accentClr: accentClr,
              borderClr: borderClr,
              textClr: textClr),
          Text(
            "${cubit.currentPage + 1}",
            style: AppTextStyles.madMd14(context, color: accentClr),
          ),
          _pageBtn(context,
              label: "التالي",
              enabled: cubit.currentPage < cubit.totalPages - 1,
              onTap: cubit.nextPage,
              accentClr: accentClr,
              borderClr: borderClr,
              textClr: textClr),
        ],
      ),
    );
  }

  Widget _pageBtn(
      BuildContext context, {
        required String label,
        required bool enabled,
        required VoidCallback onTap,
        required Color accentClr,
        required Color borderClr,
        required Color textClr,
      }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: enabled ? accentClr : borderClr),
        ),
        child: Text(
          label,
          style: AppTextStyles.madMd12(
              context, color: enabled ? accentClr : borderClr),
        ),
      ),
    );
  }
}