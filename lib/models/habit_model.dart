class HabitModel {
  final String id;
  final String title;
  final String icon;
  final DateTime createdAt;
  final List<String> completedDates;

  /// everyday | weekdays | weekends | custom
  final String frequency;

  /// Used only when frequency == custom
  /// 1 = Monday, 2 = Tuesday ... 7 = Sunday
  final List<int> customDays;

  /// Daily required target, example: 3 pages / 5 times / 1 task
  final int dailyTarget;

  /// Date key => completed amount
  /// example: {"2026-05-21": 2}
  final Map<String, int> progressByDate;

  HabitModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.createdAt,
    required this.completedDates,
    required this.frequency,
    required this.customDays,
    required this.dailyTarget,
    required this.progressByDate,
  });

  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool isScheduledToday() {
    final weekday = DateTime.now().weekday;

    switch (frequency) {
      case 'everyday':
        return true;
      case 'weekdays':
        return weekday >= DateTime.monday && weekday <= DateTime.friday;
      case 'weekends':
        return weekday == DateTime.friday || weekday == DateTime.saturday;
      case 'custom':
        return customDays.contains(weekday);
      default:
        return true;
    }
  }

  int todayProgress() {
    return progressByDate[dateKey(DateTime.now())] ?? 0;
  }

  bool isDoneToday() {
    return todayProgress() >= dailyTarget;
  }

  int get streak {
    int count = 0;
    DateTime day = DateTime.now();

    while (true) {
      final key = dateKey(day);
      final progress = progressByDate[key] ?? 0;

      if (progress >= dailyTarget) {
        count++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return count;
  }

  HabitModel copyWith({
    String? id,
    String? title,
    String? icon,
    DateTime? createdAt,
    List<String>? completedDates,
    String? frequency,
    List<int>? customDays,
    int? dailyTarget,
    Map<String, int>? progressByDate,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      progressByDate: progressByDate ?? this.progressByDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'completedDates': completedDates,
      'frequency': frequency,
      'customDays': customDays,
      'dailyTarget': dailyTarget,
      'progressByDate': progressByDate,
    };
  }

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),

      title: json['title']?.toString() ?? '',

      icon: json['icon']?.toString() ?? '🌿',

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),

      completedDates: json['completedDates'] is List
          ? List<String>.from(json['completedDates'])
          : [],

      frequency: json['frequency']?.toString() ?? 'everyday',

      customDays: json['customDays'] is List
          ? List<int>.from(
        (json['customDays'] as List).map(
              (e) => int.tryParse(e.toString()) ?? 1,
        ),
      )
          : [],

      dailyTarget: int.tryParse(json['dailyTarget']?.toString() ?? '1') ?? 1,

      progressByDate: json['progressByDate'] is Map
          ? Map<String, int>.from(
        (json['progressByDate'] as Map).map(
              (key, value) => MapEntry(
            key.toString(),
            int.tryParse(value.toString()) ?? 0,
          ),
        ),
      )
          : {},
    );
  }
}