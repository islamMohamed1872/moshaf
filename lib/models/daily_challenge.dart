import 'package:cloud_firestore/cloud_firestore.dart';

class DailyChallenge {
  final String id; // yyyy-MM-dd
  final String question;
  final List<String> options;
  final int correctIndex;
  final Timestamp createdAt;

  DailyChallenge({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.createdAt,
  });

  factory DailyChallenge.fromDoc(String id, Map<String, dynamic> m) => DailyChallenge(
    id: id,
    question: m['question'] ?? '',
    options: List<String>.from(m['options'] ?? []),
    correctIndex: m['correct_index'] ?? 0,
    createdAt: m['created_at'] ?? Timestamp.now(),
  );
}

class UserStats {
  final String uid;
  final String displayName;
  final String photoUrl;
  final int totalPoints;
  final int totalCorrectAnswers;
  final int dailyStreak;
  final int bestFastestMs; // milliseconds (lower is better)
  final DateTime? firstCorrectAt;
  UserStats({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.totalPoints,
    required this.totalCorrectAnswers,
    required this.dailyStreak,
    required this.bestFastestMs,
    required this.firstCorrectAt,
  });

  factory UserStats.fromDoc(String id, Map<String, dynamic> m) => UserStats(
    uid: id,
    displayName: m['displayName'] ?? '',
    photoUrl: m['photoUrl'] ?? '',
    totalPoints: (m['total_points'] ?? 0) as int,
    totalCorrectAnswers: (m['total_correct_answers'] ?? 0) as int,
    dailyStreak: (m['daily_streak'] ?? 0) as int,
    bestFastestMs: (m['best_fastest_ms'] ?? 9999999) as int,
    firstCorrectAt: m['first_correct_at'] != null
        ? (m['first_correct_at'] as Timestamp).toDate()
        : null,
  );
}
