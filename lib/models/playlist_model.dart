import 'package:uuid/uuid.dart';

class PlaylistItem {
  final int surah;
  final int startVerse;
  final int endVerse;

  PlaylistItem({
    required this.surah,
    required this.startVerse,
    required this.endVerse,
  });

  Map<String, dynamic> toJson() => {
    'surah': surah,
    'startVerse': startVerse,
    'endVerse': endVerse,
  };

  factory PlaylistItem.fromJson(Map<String, dynamic> json) => PlaylistItem(
    surah: json['surah'],
    startVerse: json['startVerse'],
    endVerse: json['endVerse'],
  );
}

class Playlist {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<PlaylistItem> items;

  Playlist({
    String? id,
    required this.name,
    DateTime? createdAt,
    required this.items,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: json['id'],
    name: json['name'],
    createdAt: DateTime.parse(json['createdAt']),
    items: List<PlaylistItem>.from(
      (json['items'] as List).map((e) => PlaylistItem.fromJson(e)),
    ),
  );
}