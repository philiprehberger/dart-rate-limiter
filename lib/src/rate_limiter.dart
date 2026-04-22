import 'dart:async';

/// Statistics for a rate limiter.
class RateLimiterStats {
  /// Creates rate limiter statistics.
  const RateLimiterStats({
    required this.totalRequests,
    required this.allowedRequests,
    required this.rejectedRequests,
  });

  /// Total number of acquire attempts.
  final int totalRequests;

  /// Number of attempts that were allowed.
  final int allowedRequests;

  /// Number of attempts that were rejected.
  final int rejectedRequests;
}

/// Base interface for rate limiters.
abstract class RateLimiter {
  /// Try to acquire a permit. Returns `true` if allowed, `false` if rate-limited.
  bool tryAcquire({String? key});

  /// Acquire a permit, waiting if necessary until one is available.
  ///
  /// If [timeout] is provided, throws a [TimeoutException] if a permit
  /// is not acquired within the specified duration.
  Future<void> acquire({String? key, Duration? timeout});

  /// Reset the rate limiter state.
  void reset({String? key});

  /// Returns usage statistics for the given [key], or global stats if
  /// [key] is null.
  RateLimiterStats stats({String? key});

  /// Returns the number of permits currently available for the given [key].
  int availablePermits({String? key});

  /// Returns `true` when no permits are available for the given [key].
  bool isExhausted({String? key});

  /// Returns the duration until the next permit becomes available for [key],
  /// or `null` if a permit is already available.
  Duration? retryAfter({String? key});

  /// Dispose of the rate limiter, releasing all resources.
  ///
  /// After calling dispose, any calls to [tryAcquire] or [acquire]
  /// will throw a [StateError].
  void dispose();

  /// Whether this rate limiter has been disposed.
  bool get isDisposed;
}

/// Internal statistics tracker shared across rate limiter implementations.
class Stats {
  /// Total number of acquire attempts.
  int total = 0;

  /// Number of attempts that were allowed.
  int allowed = 0;

  /// Number of attempts that were rejected.
  int rejected = 0;
}
