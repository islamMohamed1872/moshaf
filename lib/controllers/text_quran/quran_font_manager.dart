import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class QuranFontManager {
  QuranFontManager._();
  static final QuranFontManager instance = QuranFontManager._();
  final ValueNotifier<int> fontsVersion = ValueNotifier<int>(0);

  /// pages loaded into Flutter engine
  final Set<int> _loadedPages = {};

  /// pages cached on disk
  final Set<int> _cachedPages = {};

  final Queue<int> _normalQueue = Queue<int>();
  final Queue<int> _priorityQueue = Queue<int>();

  bool _isWorkerRunning = false;

  /// ✅ prevent loading too many fonts into engine
  static const int _engineKeepAliveRadius = 2; // load current ± 2 pages

  String _fontName(int page) => "QCF_P${page.toString().padLeft(3, "0")}";

  String _fontUrl(int page) =>
      "https://cdn.jsdelivr.net/gh/islamMohamed1872/qcf-fonts/QCF2${page.toString().padLeft(3, "0")}.ttf";

  QuranFontCacheManager get _cache => QuranFontCacheManager();

  /// ✅ Call on app start
  /// - caches ALL fonts on disk gradually
  /// - loads only firstPage to engine
  void warmUpAllFonts({required int firstPage}) {
    requestPriority(page: firstPage);

    // Cache all pages in background (disk only)
    for (int page = 1; page <= 604; page++) {
      if (page == firstPage) continue;
      requestBackground(page: page);
    }
  }

  /// ✅ load immediately
  void requestPriority({required int page}) {
    if (page <= 0 || page > 604) return;

    if (_loadedPages.contains(page)) return;

    _priorityQueue.remove(page);
    _priorityQueue.addFirst(page);

    // preload neighbor pages (priority background)
    for (int p = page - _engineKeepAliveRadius;
    p <= page + _engineKeepAliveRadius;
    p++) {
      if (p <= 0 || p > 604) continue;
      if (_loadedPages.contains(p)) continue;
      if (!_priorityQueue.contains(p)) {
        _priorityQueue.addLast(p);
      }
    }

    _startWorker();
  }

  /// ✅ cache only (disk), not engine
  void requestBackground({required int page}) {
    if (page <= 0 || page > 604) return;

    if (_cachedPages.contains(page)) return;
    if (_normalQueue.contains(page)) return;

    _normalQueue.add(page);
    _startWorker();
  }

  /// Ensure font is loaded into engine (blocking wait)
  Future<void> ensureFontLoaded(int page) async {
    if (_loadedPages.contains(page)) return;

    requestPriority(page: page);

    final start = DateTime.now();
    while (!_loadedPages.contains(page)) {
      await Future.delayed(const Duration(milliseconds: 20));

      if (DateTime.now().difference(start).inSeconds >= 8) {
        throw Exception("Timeout while loading font for page $page");
      }
    }
  }

  void _startWorker() {
    if (_isWorkerRunning) return;
    _isWorkerRunning = true;

    Future.microtask(() async {
      try {
        while (_priorityQueue.isNotEmpty || _normalQueue.isNotEmpty) {
          // ✅ decide whether this page is priority before removing it
          final bool isPriority = _priorityQueue.isNotEmpty;

          final int page = isPriority
              ? _priorityQueue.removeFirst()
              : _normalQueue.removeFirst();

          // 1) download/cached on disk
          await _downloadAndCache(page);

          // 2) load into engine ONLY for priority pages
          if (isPriority) {
            await _loadIntoEngine(page);
          }
        }
      } finally {
        _isWorkerRunning = false;
      }
    });
  }

  Future<void> _downloadAndCache(int page) async {
    if (_cachedPages.contains(page)) return;

    try {
      final file = await _cache.getSingleFile(_fontUrl(page));
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) _cachedPages.add(page);
    } catch (_) {}
  }

  Future<void> _loadIntoEngine(int page) async {
    if (_loadedPages.contains(page)) return;

    try {
      final file = await _cache.getSingleFile(_fontUrl(page));
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      final loader = FontLoader(_fontName(page));
      loader.addFont(
        Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
      );

      await loader.load();
      _loadedPages.add(page);
      fontsVersion.value++;

    } catch (_) {}
  }

  bool isLoaded(int page) => _loadedPages.contains(page);
  bool isCached(int page) => _cachedPages.contains(page);
}

/// ✅ persistent cache (10 years)
class QuranFontCacheManager extends CacheManager {
  static const key = 'quranFontsCache';

  static final QuranFontCacheManager _instance = QuranFontCacheManager._();

  factory QuranFontCacheManager() => _instance;

  QuranFontCacheManager._()
      : super(
    Config(
      key,
      stalePeriod: const Duration(days: 3650),
      maxNrOfCacheObjects: 1200,
    ),
  );
}
