import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/components/cache_helper.dart';
import 'package:moshaf/controllers/tasbeeh/tasbeeh_states.dart';

class TasbeehCubit extends Cubit<TasbeehStates>{
  TasbeehCubit() : super(TasbeehInitialState());
  static TasbeehCubit get(context) => BlocProvider.of(context);
  int counter = 0;
  void getCounter()async{
    counter = await CacheHelper.getData(key: "tasbeeh")??0;
    emit(GetCounterState());
  }
  void increment(){
    counter++;
    CacheHelper.saveData(key: "tasbeeh", value: counter);
    emit(TasbeehIncreaseState());
  }
  void reset(){
    counter=0;
    CacheHelper.saveData(key: "tasbeeh", value: 0);
    emit(TasbeehResetState());
  }
  List tasbeeh = [
    "سُبْحَانَ اللَّهِ",
    "الْحَمْدُ لِلَّهِِ",
    "لَا إِلَهَ إِلَّا اللَّهُِ",
    "اللَّهُ أَكْبَرُِ",
    "لَا حَوْل وَلَا قُوَّة إِلَّا بِاَللهُِ",
  ];
}

