import 'rate_limiter.dart';

/// A rate limiter using the sliding window algorithm.
///
/// Tracks timestamps of recent requests within a rolling [window]. If the
/// number of requests in the current window reaches [maxRequests], further
/// requests are either rejected or delayed.
class SlidingWindow implements RateLimiter {
  /// The maximum number of requests allowed within [window].
  final int maxRequests;

  /// The duration of the sliding window.
  final Duration window;

  final Map<String, List<DateTime>> _timestamps = {};
  final Map<String, Stats> _stats = {};
  bool _disposed = false;

  /// Creates a sliding window rate limiter.
  ///
  /// [maxRequests] is the maximum allowed requests per window (must be positive).
  /// [window] is the duration of the sliding window.
  SlidingWindow({
    required this.maxRequests,
    required this.window,
  })  : assert(maxRequests > 0, 'maxRequests must be positive'),
        assert(window > Duration.zero, 'window must be positive');

  @override
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    _timestamps.clear();
    _stats.clear();
  }

  void _checkDisposed() {
    if (_disposed) throw StateError('RateLimiter has been disposed');
  }

  List<DateTime> _timestamps_(String key) {
    return _timestamps.putIfAbsent(key, () => []);
  }

  void _cleanup(List<DateTime> timestamps) {
    final cutoff = DateTime.now().subtract(window);
    timestamps.removeWhere((t) => t.isBefore(cutoff));
  }

  @override
  bool tryAcquire({String? key}) {
    _checkDisposed();
    final k = key ?? '';
    final s = _stats[k] ??= Stats();
    s.total++;
    final ts = _timestamps_(k);
    _cleanup(ts);
    if (ts.length < maxRequests) {
      ts.add(DateTime.now());
      s.allowed++;
      return true;
    }
    s.rejected++;
    return false;
  }

  @override
  bool tryAcquireMany(int count, {String? key}) {
    _checkDisposed();
    assert(count > 0, 'count must be positive');
    final k = key ?? '';
    final s = _stats[k] ??= Stats();
    s.total++;
    final ts = _timestamps_(k);
    _cleanup(ts);
    if (ts.length + count <= maxRequests) {
      final now = DateTime.now();
      for (var i = 0; i < count; i++) {
        ts.add(now);
      }
      s.allowed++;
      return true;
    }
    s.rejected++;
    return false;
  }

  @override
  Future<void> acquire({String? key, Duration? timeout}) {
    _checkDisposed();
    final future = _doAcquire(key: key);
    if (timeout != null) return future.timeout(timeout);
    return future;
  }

  Future<void> _doAcquire({String? key}) async {
    final k = key ?? '';
    while (!tryAcquire(key: k)) {
      final ts = _timestamps_(k);
      if (ts.isNotEmpty) {
        final oldest = ts.first;
        final waitUntil = oldest.add(window);
        final waitDuration = waitUntil.difference(DateTime.now());
        if (waitDuration > Duration.zero) {
          await Future<void>.delayed(waitDuration);
        }
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  @override
  void reset({String? key}) {
    if (key != null) {
      _timestamps.remove(key);
      _stats.remove(key);
    } else {
      _timestamps.clear();
      _stats.clear();
    }
  }

  @override
  RateLimiterStats stats({String? key}) {
    _checkDisposed();
    final s = _stats[key ?? ''];
    return RateLimiterStats(
      totalRequests: s?.total ?? 0,
      allowedRequests: s?.allowed ?? 0,
      rejectedRequests: s?.rejected ?? 0,
    );
  }

  @override
  int availablePermits({String? key}) {
    _checkDisposed();
    final k = key ?? '';
    final timestamps = _timestamps[k];
    if (timestamps == null) return maxRequests;
    _cleanup(timestamps);
    return maxRequests - timestamps.length;
  }

  @override
  bool isExhausted({String? key}) {
    _checkDisposed();
    return availablePermits(key: key) == 0;
  }

  @override
  Duration? retryAfter({String? key}) {
    _checkDisposed();
    final k = key ?? '';
    final ts = _timestamps[k];
    if (ts == null || ts.isEmpty) return null;
    _cleanup(ts);
    if (ts.length < maxRequests) return null;
    final oldest = ts.first;
    final expiresAt = oldest.add(window);
    final wait = expiresAt.difference(DateTime.now());
    return wait > Duration.zero ? wait : Duration.zero;
  }
}
