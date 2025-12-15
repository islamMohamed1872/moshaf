import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/daily_challenge.dart';

enum LeaderboardSortBy { totalCorrect, fastestAnswer, longestStreak }

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _todayId() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // -------------------------------------------------------
  // 🔹 GET TODAY'S CHALLENGE
  // -------------------------------------------------------
  Future<DailyChallenge?> getChallengeByDate([String? dateId]) async {
    final id = dateId ?? _todayId();
    final doc = await _db.collection('daily_challenges').doc(id).get();
    if (!doc.exists) return null;
    return DailyChallenge.fromDoc(doc.id, doc.data()!);
  }

  // -------------------------------------------------------
  // 🔹 ADMIN – SET / UPDATE CHALLENGE
  // -------------------------------------------------------
  Future<void> setChallenge(String dateId, Map<String, dynamic> payload) {
    return _db.collection('daily_challenges').doc(dateId).set(
      {
        ...payload,
        'created_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // -------------------------------------------------------
  // 🔹 SUBMIT ANSWER
  // -------------------------------------------------------
  Future<void> submitAnswer({
    required String uid,
    required String dateId,
    required int selectedIndex,
    required bool isCorrect,
    required int responseMs,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final answerRef =
    _db.collection('user_answers').doc(uid).collection('answers').doc(dateId);

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final answerSnap = await tx.get(answerRef);

      // If the user already answered today → update answer only
      if (answerSnap.exists) {
        tx.set(answerRef, {
          'selected_index': selectedIndex,
          'is_correct': isCorrect,
          'response_ms': responseMs,
          'timestamp': FieldValue.serverTimestamp(),
        });
        return;
      }

      // If first time answering today
      if (!userSnap.exists) {
        tx.set(userRef, {
          'displayName': FirebaseAuth.instance.currentUser==null?"User": FirebaseAuth.instance.currentUser!.displayName,
          'photoUrl': '',
          'country': '',
          'city': '',
          'total_points': isCorrect ? 10 : 0,
          'total_correct_answers': isCorrect ? 1 : 0,
          'daily_streak': 1,
          'last_answer_date': dateId,
          'best_fastest_ms': isCorrect ? responseMs : null,
        });
      } else {
        final data = userSnap.data()!;
        final lastDate = data['last_answer_date'];
        final yesterday = _yesterday(dateId);

        // STREAK
        int newStreak = 1;
        if (lastDate == dateId) {
          newStreak = data['daily_streak'];
        } else if (lastDate == yesterday) {
          newStreak = (data['daily_streak'] ?? 0) + 1;
        }

        // FASTEST TIME
        int bestFastest = data['best_fastest_ms'] ?? 99999999;
        if (isCorrect && responseMs < bestFastest) {
          bestFastest = responseMs;
        }

        tx.set(
          userRef,
          {
            'total_points':
            (data['total_points'] ?? 0) + (isCorrect ? 10 : 0),
            'total_correct_answers':
            (data['total_correct_answers'] ?? 0) + (isCorrect ? 1 : 0),
            'daily_streak': newStreak,
            'last_answer_date': dateId,
            'best_fastest_ms': bestFastest,
          },
          SetOptions(merge: true),
        );
      }

      // Write answer
      tx.set(answerRef, {
        'selected_index': selectedIndex,
        'is_correct': isCorrect,
        'response_ms': responseMs,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  String _yesterday(String dateId) {
    final dt = DateTime.parse(dateId);
    return DateFormat('yyyy-MM-dd').format(dt.subtract(const Duration(days: 1)));
  }

  // -------------------------------------------------------
  // 🔹 GET LEADERBOARD
  // -------------------------------------------------------
  Future<List<UserStats>> getLeaderboard({
    required int limit,
    String? country,
    String? city,
    required LeaderboardSortBy sortBy,
  }) async {
    Query q = _db.collection('users');

    if (country != null && country.isNotEmpty) {
      q = q.where('country', isEqualTo: country);
    }
    if (city != null && city.isNotEmpty) {
      q = q.where('city', isEqualTo: city);
    }

    switch (sortBy) {
      case LeaderboardSortBy.totalCorrect:
        q = q.orderBy('total_correct_answers', descending: true);
        break;
      case LeaderboardSortBy.fastestAnswer:
        q = q.orderBy('best_fastest_ms', descending: false);
        break;
      case LeaderboardSortBy.longestStreak:
        q = q.orderBy('daily_streak', descending: true);
        break;
    }

    final snap = await q.limit(limit).get();

    return snap.docs
        .map((d) => UserStats.fromDoc(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }


  Future<void> saveUserDailyAnswer({
    required String uid,
    required String challengeId,
    required int selectedIndex,
  }) async {
    final doc = FirebaseFirestore.instance
        .collection("daily_challenge_answers")
        .doc(uid);

    await doc.set({
      challengeId: selectedIndex,
    }, SetOptions(merge: true));
  }


  Future<int?> loadUserDailyAnswer({
    required String uid,
    required String challengeId,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection("user_answers")
        .doc(uid)
        .collection("answers")
        .doc(challengeId)
        .get();

    if (!doc.exists) return null;

    final data = doc.data()!;

    // Firestore uses snake_case
    if (data.containsKey("selected_index")) {
      return data["selected_index"];
    }

    return null;
  }


}
