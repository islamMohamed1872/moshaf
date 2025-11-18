import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/components/cache_helper.dart';
import 'tasbeeh_states.dart';

class TasbeehCubit extends Cubit<TasbeehStates> {
  TasbeehCubit() : super(TasbeehInitialState());
  static TasbeehCubit get(context) => BlocProvider.of(context);

  int totalCount = 0;
  int? selectedIndex = 0;
  bool showInput = false;
  List<Map<String, dynamic>> tasbeehList = [];
  final TextEditingController tasbeehController = TextEditingController();

  Future<void> getData() async {
    totalCount = await CacheHelper.getData(key: "totalTasbeehCount") ?? 0;
    tasbeehList = (await CacheHelper.getData(key: "tasbeehList"))?.cast<Map<String, dynamic>>() ?? [
      {"text": "سُبْحَانَ اللَّهِ", "count": 0},
      {"text": "الْحَمْدُ لِلَّهِ", "count": 0},
      {"text": "لَا إِلَهَ إِلَّا اللَّهُ", "count": 0},
      {"text": "اللَّهُ أَكْبَرُ", "count": 0},
      {"text": "لَا حَوْل وَلَا قُوَّة إِلَّا بِاللَّهِ", "count": 0},
    ];
    emit(GetCounterState());
  }

  void selectTasbeeh(int index) {
    selectedIndex = index;
    emit(TasbeehSelectedState());
  }

  void increment() {
    if (selectedIndex == null) return;
    totalCount++;
    tasbeehList[selectedIndex!]["count"]++;

    CacheHelper.saveData(key: "totalTasbeehCount", value: totalCount);
    CacheHelper.saveData(key: "tasbeehList", value: tasbeehList);
    emit(TasbeehIncreaseState());
  }

  void resetAll() {
    totalCount = 0;
    for (var item in tasbeehList) {
      item["count"] = 0;
    }
    CacheHelper.saveData(key: "totalTasbeehCount", value: totalCount);
    CacheHelper.saveData(key: "tasbeehList", value: tasbeehList);
    emit(TasbeehResetState());
  }

  void addTasbeeh(String text) {
    tasbeehList.insert(0,{"text": text, "count": 0});
    CacheHelper.saveData(key: "tasbeehList", value: tasbeehList);
    emit(AddTasbeehState());
  }

  void toggleShowInput(){
    showInput = !showInput;
    emit(ShowInputState());
  }

  void deleteTasbeeh(int index) {
    tasbeehList.removeAt(index);
    CacheHelper.saveData(key: "tasbeehList", value: tasbeehList);
    emit(DeleteTasbeehState());
  }
}
