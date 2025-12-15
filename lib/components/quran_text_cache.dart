import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class QuranTextCache {
  static const _dataFile = 'quran_text.json';
  static const _flagFile = 'quran_text_cached.flag';

  static Future<bool> isCached() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_flagFile').existsSync();
  }

  static Future<void> save(dynamic jsonData) async {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$_dataFile')
        .writeAsString(jsonEncode(jsonData));
    await File('${dir.path}/$_flagFile').writeAsString('cached');
  }

  static Future<dynamic> load() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_dataFile');
    return jsonDecode(await file.readAsString());
  }
}
