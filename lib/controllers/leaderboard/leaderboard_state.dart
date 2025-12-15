part of 'leaderboard_cubit.dart';



abstract class LeaderboardState extends Equatable {
  @override List<Object?> get props => [];
}
class LeaderboardInitial extends LeaderboardState {}
class LeaderboardLoading extends LeaderboardState {}
class LeaderboardLoaded extends LeaderboardState {
  final List<UserStats> rows;
  final LeaderboardSortBy sortBy;
  LeaderboardLoaded({required this.rows, required this.sortBy});
  @override List<Object?> get props => [rows, sortBy];
}

class LeaderboardError extends LeaderboardState {
  final String message;
  LeaderboardError(this.message);
  @override List<Object?> get props => [message];
}
