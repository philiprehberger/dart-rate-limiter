import 'dart:async';

import 'rate_limiter.dart';

/// A rate limiter that combines multiple [RateLimiter] instances.
///
/// A request is only allowed when **all** inner limiters permit it. This is
/// useful for enforcing multi-tier rate limits such as "10 requests per second
/// **and** 1,000 requests per hour".
class CompositeRateLimiter implements RateLimiter {
  /// The inner rate limiters that must all allow a request.
  final List<RateLimiter> limiters;

  final Map<String, Stats> _stats = {};

  /// Creates a composite rate limiter.
  ///
  /// [limiters] must contain at least one rate limiter.
  CompositeRateLimiter(this.limiters)
      : assert(limiters.isNotEmpty, 'limiters must not be empty');

  Stats _getStats(String key) => _stats[key] ??= Stats();

  @override
  bool tryAcquire({String? key}) {
    final k = key ?? '';
    final s = _getStats(k);
    s.total++;

    // Check all limiters before acquiring — if any would reject, abort.
    for (final limiter in limiters) {
      if (limiter.availablePermits(key: key) <= 0) {
        s.rejected++;
        return false;
      }
    }

    // All limiters have capacity — acquire from each.
    for (final limiter in limiters) {
      limiter.tryAcquire(key: key);
    }
    s.allowed++;
    return true;
  }

  @override
  Future<void> acquire({String? key, Duration? timeout}) {
    final future = _doAcquire(key: key);
    if (timeout != null) return future.timeout(timeout);
    return future;
  }

  Future<void> _doAcquire({String? key}) async {
    while (!tryAcquire(key: key)) {
      final wait = retryAfter(key: key);
      await Future<void>.delayed(wait ?? const Duration(milliseconds: 10));
    }
  }

  @override
  void reset({String? key}) {
    for (final limiter in limiters) {
      limiter.reset(key: key);
    }
    if (key != null) {
      _stats.remove(key);
    } else {
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
    var min = limiters.first.availablePermits(key: key);
    for (var i = 1; i < limiters.length; i++) {
      final p = limiters[i].availablePermits(key: key);
      if (p < min) min = p;
    }
    return min;
  }

  @override
  bool isExhausted({String? key}) {
    return limiters.any((l) => l.isExhausted(key: key));
  }

  @override
  Duration? retryAfter({String? key}) {
    Duration? max;
    for (final limiter in limiters) {
      final wait = limiter.retryAfter(key: key);
      if (wait != null && (max == null || wait > max)) {
        max = wait;
      }
    }
    return max;
  }
}
