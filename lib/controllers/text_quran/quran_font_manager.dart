import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class QuranFontManager {
  QuranFontManager._();

  static final QuranFontManager instance = QuranFontManager._();

  final Set<int> _loadedPages = {}; // pages loaded into engine
  final Set<int> _cachedPages = {}; // pages downloaded & cached on disk

  final Queue<int> _normalQueue = Queue<int>();
  final Queue<int> _priorityQueue = Queue<int>();

  bool _isWorkerRunning = false;

  String _fontName(int page) => "QCF_P${page.toString().padLeft(3, "0")}";

  String _fontUrl(int page) =>
      "https://cdn.jsdelivr.net/gh/islamMohamed1872/qcf-fonts/QCF2${page.toString().padLeft(3, "0")}.ttf";

  /// Call on app start
  void warmUpAllFonts({required int firstPage}) {
    // Prioritize first page
    requestPriority(page: firstPage);

    // Add the rest in background queue
    for (int page = 1; page <= 604; page++) {
      if (page == firstPage) continue;
      requestBackground(page: page);
    }
  }

  /// User navigated to a page -> load it immediately
  void requestPriority({required int page}) {
    if (_loadedPages.contains(page)) return;

    _priorityQueue.remove(page);
    _priorityQueue.addFirst(page);

    _startWorker();
  }

  /// Background prefetch
  void requestBackground({required int page}) {
    if (_cachedPages.contains(page)) return;

    if (!_normalQueue.contains(page)) {
      _normalQueue.add(page);
    }

    _startWorker();
  }

  /// Ensure font for page is loaded into Flutter engine
  Future<void> ensureFontLoaded(int page) async {
    if (_loadedPages.contains(page)) return;

    // This triggers priority loading
    requestPriority(page: page);

    // wait until loaded
    while (!_loadedPages.contains(page)) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  /// Worker loop
  void _startWorker() {
    if (_isWorkerRunning) return;
    _isWorkerRunning = true;

    Future.microtask(() async {
      while (_priorityQueue.isNotEmpty || _normalQueue.isNotEmpty) {
        final int page = _priorityQueue.isNotEmpty
            ? _priorityQueue.removeFirst()
            : _normalQueue.removeFirst();

        // Download+cache
        await _downloadAndCache(page);

        // Load into engine (only for priority pages, OR preload a small set)
        if (_priorityQueue.isNotEmpty || !_loadedPages.contains(page)) {
          await _loadIntoEngine(page);
        }
      }

      _isWorkerRunning = false;
    });
  }

  Future<void> _downloadAndCache(int page) async {
    if (_cachedPages.contains(page)) return;

    try {
      final file = await DefaultCacheManager().getSingleFile(_fontUrl(page));
      final bytes = await file.readAsBytes();

      if (bytes.isNotEmpty) {
        _cachedPages.add(page);
      }
    } catch (_) {}
  }

  Future<void> _loadIntoEngine(int page) async {
    if (_loadedPages.contains(page)) return;

    final fontName = _fontName(page);

    try {
      final file = await DefaultCacheManager().getSingleFile(_fontUrl(page));
      final bytes = await file.readAsBytes();

      final loader = FontLoader(fontName);
      loader.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
      await loader.load();

      _loadedPages.add(page);
    } catch (_) {}
  }

  bool isLoaded(int page) => _loadedPages.contains(page);
  bool isCached(int page) => _cachedPages.contains(page);
}
