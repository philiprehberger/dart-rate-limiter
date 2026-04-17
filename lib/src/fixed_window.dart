import 'rate_limiter.dart';

/// A rate limiter using the fixed window algorithm.
///
/// Allows up to [maxRequests] within each fixed [window] duration.
/// The window resets completely after each interval.
class FixedWindow implements RateLimiter {
  /// Creates a fixed window rate limiter.
  FixedWindow({required this.maxRequests, required this.window})
      : assert(maxRequests > 0),
        assert(window > Duration.zero);

  /// Maximum number of requests allowed per window.
  final int maxRequests;

  /// Duration of each fixed window.
  final Duration window;

  final Map<String, _WindowState> _windows = {};
  final Map<String, Stats> _stats = {};
  bool _disposed = false;

  @override
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    _windows.clear();
    _stats.clear();
  }

  void _checkDisposed() {
    if (_disposed) throw StateError('RateLimiter has been disposed');
  }

  _WindowState _getOrResetWindow(String key) {
    final now = DateTime.now();
    var state = _windows[key];
    if (state == null || now.difference(state.windowStart) >= window) {
      state = _WindowState(windowStart: now, count: 0);
      _windows[key] = state;
    }
    return state;
  }

  Stats _getStats(String key) => _stats[key] ??= Stats();

  @override
  bool tryAcquire({String? key}) {
    _checkDisposed();
    final k = key ?? '';
    final s = _getStats(k);
    s.total++;
    final state = _getOrResetWindow(k);
    if (state.count < maxRequests) {
      state.count++;
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
    while (!tryAcquire(key: key)) {
      await Future<void>.delayed(window);
    }
  }

  @override
  void reset({String? key}) {
    if (key != null) {
      _windows.remove(key);
      _stats.remove(key);
    } else {
      _windows.clear();
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
    final state = _getOrResetWindow(key ?? '');
    return maxRequests - state.count;
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
    final state = _windows[k];
    if (state == null) return null;
    final now = DateTime.now();
    if (now.difference(state.windowStart) >= window) return null;
    if (state.count < maxRequests) return null;
    final windowEnd = state.windowStart.add(window);
    final wait = windowEnd.difference(now);
    return wait > Duration.zero ? wait : Duration.zero;
  }
}

class _WindowState {
  _WindowState({required this.windowStart, required this.count});
  final DateTime windowStart;
  int count;
}
