import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/daily_challenge.dart';
import '../../services/firestore_service.dart';

part 'daily_challenge_state.dart';

class DailyChallengeCubit extends Cubit<DailyChallengeState> {
  DailyChallengeCubit() : super(DailyChallengeInitial());
  static DailyChallengeCubit get(context) => BlocProvider.of(context);

  final FirestoreService _fs = FirestoreService();

  DailyChallenge? dailyChallenge;
  int? savedAnswer; // 👉 Previously selected answer (if exists)

  DateTime? _startedAt;
  int _startMs = 0;

  // -----------------------------
  //   LOAD TODAY'S CHALLENGE
  // -----------------------------
  Future<void> loadToday() async {
    emit(DailyChallengeLoading());

    final todayId = _getTodayId();
    final challenge = await _fs.getChallengeByDate(todayId);

    if (challenge == null) {
      emit(DailyChallengeEmpty());
      return;
    }

    dailyChallenge = challenge;

    // Load saved answer from Firestore
    final uid = FirebaseAuth.instance.currentUser!.uid;
    savedAnswer = await _fs.loadUserDailyAnswer(
      uid: uid,
      challengeId: challenge.id,
    );

    emit(DailyChallengeLoaded());
  }

  // -----------------------------
  //          TIMER
  // -----------------------------
  void startTimer() {
    _startedAt = DateTime.now();
    _startMs = _startedAt!.millisecondsSinceEpoch;
  }

  // -----------------------------
  //      SUBMIT ANSWER
  // -----------------------------
  Future<void> submitAnswer({
    required String uid,
    required DailyChallenge challenge,
    required int selectedIndex,
  }) async {
    final now = DateTime.now();

    final responseMs =
        now.millisecondsSinceEpoch - (_startMs == 0 ? now.millisecondsSinceEpoch : _startMs);

    final isCorrect = selectedIndex == challenge.correctIndex;

    emit(DailyChallengeSubmitting());

// Save locally so UI restores answer when user returns
    savedAnswer = selectedIndex;
    // Save to Firestore (with response time)
     _fs.submitAnswer(
      uid: uid,
      dateId: challenge.id,
      selectedIndex: selectedIndex,
      isCorrect: isCorrect,
      responseMs: responseMs,
    );



    emit(DailyChallengeSubmitted(
      isCorrect: isCorrect,
      responseMs: responseMs,
    ));
  }

  // -----------------------------
  //         HELPERS
  // -----------------------------
  String _getTodayId() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
