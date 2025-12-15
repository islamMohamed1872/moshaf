import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/daily_challenge.dart';
import '../../models/leaderboard_row.dart';
import '../../services/firestore_service.dart';


part 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final FirestoreService _fs = FirestoreService();
  LeaderboardCubit() : super(LeaderboardInitial());

  Future<void> load({
    required int limit,
    String? country,
    String? city,
    required LeaderboardSortBy sortBy,
  }) async {
    emit(LeaderboardLoading());
    try {
      final rows = await _fs.getLeaderboard(limit: limit, country: country, city: city, sortBy: sortBy);
      emit(LeaderboardLoaded(rows: rows, sortBy: sortBy));
    } catch (e) {
      emit(LeaderboardError(e.toString()));
    }
  }
}
