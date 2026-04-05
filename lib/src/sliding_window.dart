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
  final Map<String, _Stats> _stats = {};

  /// Creates a sliding window rate limiter.
  ///
  /// [maxRequests] is the maximum allowed requests per window (must be positive).
  /// [window] is the duration of the sliding window.
  SlidingWindow({
    required this.maxRequests,
    required this.window,
  })  : assert(maxRequests > 0, 'maxRequests must be positive'),
        assert(window > Duration.zero, 'window must be positive');

  List<DateTime> _timestamps_(String key) {
    return _timestamps.putIfAbsent(key, () => []);
  }

  void _cleanup(List<DateTime> timestamps) {
    final cutoff = DateTime.now().subtract(window);
    timestamps.removeWhere((t) => t.isBefore(cutoff));
  }

  @override
  bool tryAcquire({String? key}) {
    final k = key ?? '';
    final s = _stats[k] ??= _Stats();
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
  Future<void> acquire({String? key, Duration? timeout}) {
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
    final s = _stats[key ?? ''];
    return RateLimiterStats(
      totalRequests: s?.total ?? 0,
      allowedRequests: s?.allowed ?? 0,
      rejectedRequests: s?.rejected ?? 0,
    );
  }

  @override
  int availablePermits({String? key}) {
    final k = key ?? '';
    final timestamps = _timestamps[k];
    if (timestamps == null) return maxRequests;
    _cleanup(timestamps);
    return maxRequests - timestamps.length;
  }

  @override
  bool isExhausted({String? key}) => availablePermits(key: key) == 0;
}

class _Stats {
  int total = 0;
  int allowed = 0;
  int rejected = 0;
}
