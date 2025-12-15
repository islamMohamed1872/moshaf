class LeaderboardRow {
  final String uid;
  final String displayName;
  final String photoUrl;
  final int totalPoints;
  final int totalCorrectAnswers;
  final int dailyStreak;
  final int bestFastestMs;

  LeaderboardRow({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.totalPoints,
    required this.totalCorrectAnswers,
    required this.dailyStreak,
    required this.bestFastestMs,
  });

  factory LeaderboardRow.fromMap(String uid, Map<String, dynamic> data) {
    return LeaderboardRow(
      uid: uid,
      displayName: data['displayName'] ?? 'User',
      photoUrl: data['photoUrl'] ?? '',
      totalPoints: data['total_points'] ?? 0,
      totalCorrectAnswers: data['total_correct_answers'] ?? 0,
      dailyStreak: data['daily_streak'] ?? 0,
      bestFastestMs: data['best_fastest_ms'] ?? 99999999,
    );
  }
}
