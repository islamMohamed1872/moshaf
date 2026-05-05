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
      final rows = await _fs.getLeaderboard(
        limit: limit,
        country: country,
        city: city,
        sortBy: sortBy,
      );

      if (sortBy == LeaderboardSortBy.totalCorrect) {
        rows.sort((a, b) {
          // 1️⃣ Points DESC
          final pointsCompare = b.totalPoints.compareTo(a.totalPoints);
          if (pointsCompare != 0) return pointsCompare;

          // 2️⃣ Earlier first_correct_at wins
          final aTime = a.firstCorrectAt;
          final bTime = b.firstCorrectAt;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1; // null goes last
          if (bTime == null) return -1;

          return aTime.compareTo(bTime); // earlier first
        });
      }

      emit(LeaderboardLoaded(rows: rows, sortBy: sortBy));
    } catch (e) {
      emit(LeaderboardError(e.toString()));
    }
  }
}
