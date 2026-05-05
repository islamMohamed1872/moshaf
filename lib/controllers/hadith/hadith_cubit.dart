

// ============================================================
// FILE 3: lib/controllers/hadith/hadith_cubit.dart
// ============================================================

import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../../services/hadith_service.dart';
import 'hadith_states.dart';

// import hadith_states and hadith_service (same package)

class HadithCubit extends Cubit<HadithStates> {
  HadithCubit() : super(HadithInitialState());

  static HadithCubit get(BuildContext context) => BlocProvider.of(context);

  final HadithService service = HadithService();

  // ── State ──────────────────────────────────────────────────
  String selectedEdition = 'ara-bukhari';
  String get selectedBookName => kHadithBooks[selectedEdition] ?? selectedEdition;

  /// The converted map in your app's format (same as fortyHadithOfNawawi)
  Map<String, dynamic> hadithMap = {};

  bool isLoading = false;
  String? error;

  // Pagination
  static const int pageSize = 50;
  int currentPage = 0;
  List<dynamic> get allHadiths => (hadithMap['azkar'] as List?) ?? [];
  int get totalPages => (allHadiths.length / pageSize).ceil();

  /// Returns the current page's hadiths as a partial map
  /// (same format as hadithMap but with only pageSize items)
  Map<String, dynamic> get currentPageMap => {
    "category": hadithMap['category'] ?? '',
    "azkar": currentPageItems,
  };

  List<dynamic> get currentPageItems {
    final start = currentPage * pageSize;
    final end   = (start + pageSize).clamp(0, allHadiths.length);
    return allHadiths.sublist(start, end);
  }

  // ── Actions ────────────────────────────────────────────────

  Future<void> loadBook(String edition) async {
    selectedEdition = edition;
    currentPage     = 0;
    isLoading       = true;
    error           = null;
    emit(HadithLoadingState());

    try {
      final raw = await service.fetchAll(edition);
      final hadiths = (raw['hadiths'] as List? ?? [])
          .where((h) {
        final text = (h['text'] ?? h['body'] ?? '').toString().trim();
        return text.isNotEmpty;
      })
          .toList();
      print(hadiths);
      hadithMap = HadithService.toAzkarFormat(
        bookName: kHadithBooks[edition] ?? edition,
        hadiths: hadiths,
      );
      isLoading = false;
      emit(HadithLoadedState());
    } catch (e) {
      isLoading = false;
      error = e.toString();
      emit(HadithErrorState(error!));
    }
  }

  void nextPage() {
    if (currentPage < totalPages - 1) {
      currentPage++;
      emit(HadithPageChangedState());
    }
  }

  void prevPage() {
    if (currentPage > 0) {
      currentPage--;
      emit(HadithPageChangedState());
    }
  }

  void changeBook(String edition) {
    emit(HadithBookChangedState());
    loadBook(edition);
  }
}
