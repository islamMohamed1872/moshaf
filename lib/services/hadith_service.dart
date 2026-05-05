// ============================================================
// FILE 1: lib/services/hadith_service.dart
// ============================================================
// Fetches hadiths from fawazahmed0/hadith-api (jsDelivr CDN).
// No API key. No rate limits.
// ============================================================

import 'dart:convert';
import 'package:dio/dio.dart';

const _base = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

/// All supported books with their Arabic display names
const Map<String, String> kHadithBooks = {
  'ara-bukhari':       'صحيح البخاري',
  'ara-muslim':        'صحيح مسلم',
  'ara-abudawud':      'سنن أبي داود',
  'ara-tirmidhi':      'جامع الترمذي',
  'ara-ibnmajah':      'سنن ابن ماجه',
  'ara-nasai':         'سنن النسائي',
  'ara-malik':         'موطأ مالك',
  'ara-nawawi40':      'الأربعون النووية',
  'ara-riyadussalihin':'رياض الصالحين',
};

class HadithService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // ── Fetch a single hadith by number ──────────────────────
  Future<Map<String, dynamic>> fetchOne(String edition, int number) async {
    final res = await _dio.get('$_base/$edition/$number.json');
    return res.data as Map<String, dynamic>;
  }

  // ── Fetch all hadiths in a book ───────────────────────────
  // Returns the raw API map: { metadata: {...}, hadiths: [...] }
  Future<Map<String, dynamic>> fetchAll(String edition) async {
    final res = await _dio.get('$_base/$edition.min.json');
    final data = res.data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    return data as Map<String, dynamic>;
  }

  // ── Convert API response → your app's map format ─────────
  // Mirrors exactly the structure of fortyHadithOfNawawi in azkar.dart:
  //   { "category": "...", "azkar": [ { "zekr": "...", "count": 1, "reference": "..." } ] }
  static Map<String, dynamic> toAzkarFormat({
    required String bookName,  // Arabic display name, e.g. "صحيح البخاري"
    required List<dynamic> hadiths,
  }) {
    return {
      "category": bookName,
      "azkar": hadiths.map<Map<String, dynamic>>((h) {
        final num  = h['hadithnumber'] ?? h['number'] ?? '';
        final text = h['text'] ?? h['body'] ?? '';
        return {
          "zekr":      text.toString().trim(),
          "count":     1,
          "reference": "حديث رقم $num",
        };
      }).toList(),
    };
  }
}
