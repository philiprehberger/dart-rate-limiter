/// Base interface for rate limiters.
abstract class RateLimiter {
  /// Try to acquire a permit. Returns `true` if allowed, `false` if rate-limited.
  bool tryAcquire({String? key});

  /// Acquire a permit, waiting if necessary until one is available.
  Future<void> acquire({String? key});

  /// Reset the rate limiter state.
  void reset({String? key});
}
