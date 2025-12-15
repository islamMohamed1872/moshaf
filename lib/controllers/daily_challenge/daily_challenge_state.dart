part of 'daily_challenge_cubit.dart';

abstract class DailyChallengeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DailyChallengeInitial extends DailyChallengeState {}
class DailyChallengeLoading extends DailyChallengeState {}
class DailyChallengeEmpty extends DailyChallengeState {}
class DailyChallengeLoaded extends DailyChallengeState {}
class DailyChallengeSubmitting extends DailyChallengeState {}
class DailyChallengeSubmitted extends DailyChallengeState {
  final bool isCorrect;
  final int responseMs;
  DailyChallengeSubmitted({required this.isCorrect, required this.responseMs});
  @override List<Object?> get props => [isCorrect, responseMs];
}
