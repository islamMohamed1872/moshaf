import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reciter_model.dart';

class Mp3QuranService {
  static const _baseUrl = 'https://www.mp3quran.net/api/v3/reciters';

  Future<List<Reciter>> getReciters({
    String language = 'ar',
    int? reciter,
    int? rewaya,
    int? sura,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'language': language,
      if (reciter != null) 'reciter': '$reciter',
      if (rewaya != null) 'rewaya': '$rewaya',
      if (sura != null) 'sura': '$sura',
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load reciters');
    }

    final data = jsonDecode(res.body);
    return (data['reciters'] as List)
        .map((e) => Reciter.fromJson(e))
        .toList();
  }
}
