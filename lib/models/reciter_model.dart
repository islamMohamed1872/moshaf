class Reciter {
  final int id;
  final String name;
  final List<Moshaf> moshaf;

  Reciter({
    required this.id,
    required this.name,
    required this.moshaf,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'],
      name: json['name'],
      moshaf: (json['moshaf'] as List)
          .map((e) => Moshaf.fromJson(e))
          .toList(),
    );
  }
}

class Moshaf {
  final int id;
  final String name;
  final String server;
  final String surahList;

  Moshaf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahList,
  });

  factory Moshaf.fromJson(Map<String, dynamic> json) {
    return Moshaf(
      id: json['id'],
      name: json['name'],
      server: json['server'],
      surahList: json['surah_list'],
    );
  }

  bool hasSurah(int surah) {
    return surahList.split(',').contains(surah.toString());
  }
}
