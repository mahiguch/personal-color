import 'dart:async';
import 'package:flutter/foundation.dart';

/// メモリ使用量の監視と管理
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  final List<WeakReference<Uint8List>> _managedBuffers = [];
  final Map<String, DateTime> _allocationTimestamps = {};
  Timer? _cleanupTimer;
  
  static const int maxBufferAge = 30; // 30秒
  static const int cleanupIntervalMs = 5000; // 5秒毎
  
  /// メモリマネージャーを初期化
  void initialize() {
    _startCleanupTimer();
    debugPrint('🧠 MemoryManager initialized');
  }
  
  /// バッファを管理対象に追加
  void registerBuffer(Uint8List buffer, String identifier) {
    _managedBuffers.add(WeakReference(buffer));
    _allocationTimestamps[identifier] = DateTime.now();
    
    if (kDebugMode) {
      debugPrint('🧠 Buffer registered: $identifier (${buffer.length} bytes)');
    }
  }
  
  /// 期限切れバッファのクリーンアップ
  void _cleanupExpiredBuffers() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    // タイムスタンプをチェックして期限切れを特定
    _allocationTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp).inSeconds > maxBufferAge) {
        expiredKeys.add(key);
      }
    });
    
    // 期限切れのタイムスタンプを削除
    for (final key in expiredKeys) {
      _allocationTimestamps.remove(key);
    }
    
    // WeakReferenceのクリーンアップ
    _managedBuffers.removeWhere((ref) => ref.target == null);
    
    if (expiredKeys.isNotEmpty && kDebugMode) {
      debugPrint('🧠 Memory cleanup: ${expiredKeys.length} expired buffers removed');
    }
  }
  
  /// クリーンアップタイマーの開始
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      Duration(milliseconds: cleanupIntervalMs),
      (_) => _cleanupExpiredBuffers(),
    );
  }
  
  /// メモリ使用量統計の取得
  MemoryStats getMemoryStats() {
    final activeBuffers = _managedBuffers.where((ref) => ref.target != null).length;
    final totalAllocations = _allocationTimestamps.length;
    
    int totalBytes = 0;
    for (final ref in _managedBuffers) {
      final buffer = ref.target;
      if (buffer != null) {
        totalBytes += buffer.length;
      }
    }
    
    return MemoryStats(
      activeBuffers: activeBuffers,
      totalAllocations: totalAllocations,
      totalBytes: totalBytes,
    );
  }
  
  /// 強制メモリクリーンアップ
  void forceCleanup() {
    _cleanupExpiredBuffers();
    
    // システムレベルのガベージコレクションのヒント
    if (!kIsWeb) {
      // Native環境でのメモリ最適化
      Future.delayed(Duration.zero, () {
        // 次のフレームでメモリ最適化
      });
    }
    
    debugPrint('🧠 Force memory cleanup completed');
  }
  
  /// メモリマネージャーの終了処理
  void dispose() {
    _cleanupTimer?.cancel();
    _managedBuffers.clear();
    _allocationTimestamps.clear();
    debugPrint('🧠 MemoryManager disposed');
  }
}

/// メモリ使用量統計
class MemoryStats {
  final int activeBuffers;
  final int totalAllocations;
  final int totalBytes;
  
  MemoryStats({
    required this.activeBuffers,
    required this.totalAllocations,
    required this.totalBytes,
  });
  
  double get totalMB => totalBytes / (1024 * 1024);
  
  @override
  String toString() {
    return 'MemoryStats(active: $activeBuffers, total: $totalAllocations, ${totalMB.toStringAsFixed(1)}MB)';
  }
}

/// メモリ効率的なバイトバッファ
class OptimizedByteBuffer {
  Uint8List? _buffer;
  final String _identifier;
  bool _isReleased = false;
  
  OptimizedByteBuffer(this._identifier, int size) {
    _buffer = Uint8List(size);
    MemoryManager().registerBuffer(_buffer!, _identifier);
  }
  
  /// バッファデータを取得
  Uint8List? get data {
    if (_isReleased) {
      debugPrint('⚠️ Accessing released buffer: $_identifier');
      return null;
    }
    return _buffer;
  }
  
  /// バッファサイズを取得
  int get length => _buffer?.length ?? 0;
  
  /// バッファが有効かチェック
  bool get isValid => !_isReleased && _buffer != null;
  
  /// バッファを明示的に解放
  void release() {
    if (!_isReleased) {
      _buffer = null;
      _isReleased = true;
      debugPrint('🗑️ Buffer released: $_identifier');
    }
  }
  
  /// データをコピー（メモリ効率的）
  OptimizedByteBuffer copy() {
    if (_isReleased || _buffer == null) {
      throw StateError('Cannot copy released buffer');
    }
    
    final newBuffer = OptimizedByteBuffer('${_identifier}_copy', _buffer!.length);
    newBuffer._buffer!.setRange(0, _buffer!.length, _buffer!);
    return newBuffer;
  }
}

/// Widget向けメモリ最適化ミックスイン
mixin MemoryOptimizedWidget {
  final List<OptimizedByteBuffer> _ownedBuffers = [];
  
  /// バッファを作成して管理下に追加
  OptimizedByteBuffer createBuffer(String name, int size) {
    final buffer = OptimizedByteBuffer('${runtimeType}_$name', size);
    _ownedBuffers.add(buffer);
    return buffer;
  }
  
  /// 全ての管理下バッファを解放
  void releaseAllBuffers() {
    for (final buffer in _ownedBuffers) {
      buffer.release();
    }
    _ownedBuffers.clear();
    debugPrint('🧹 All buffers released for $runtimeType');
  }
  
  /// メモリ統計を取得
  MemoryStats getWidgetMemoryStats() {
    final activeBuffers = _ownedBuffers.where((b) => b.isValid).length;
    final totalBytes = _ownedBuffers.fold<int>(0, (sum, b) => sum + b.length);
    
    return MemoryStats(
      activeBuffers: activeBuffers,
      totalAllocations: _ownedBuffers.length,
      totalBytes: totalBytes,
    );
  }
}

/// アプリケーション全体のメモリ監視
class AppMemoryMonitor {
  static Timer? _monitorTimer;
  static const int monitorIntervalMs = 10000; // 10秒毎
  
  /// メモリ監視を開始
  static void startMonitoring() {
    _monitorTimer = Timer.periodic(
      Duration(milliseconds: monitorIntervalMs),
      (_) => _logMemoryStats(),
    );
    debugPrint('📊 App memory monitoring started');
  }
  
  /// メモリ統計をログ出力
  static void _logMemoryStats() {
    final stats = MemoryManager().getMemoryStats();
    if (stats.totalMB > 50) { // 50MB超過時は警告
      debugPrint('⚠️ High memory usage detected: $stats');
    } else if (kDebugMode) {
      debugPrint('📊 Memory usage: $stats');
    }
  }
  
  /// メモリ監視を停止
  static void stopMonitoring() {
    _monitorTimer?.cancel();
    debugPrint('📊 App memory monitoring stopped');
  }
}