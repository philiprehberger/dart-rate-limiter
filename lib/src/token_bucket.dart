import 'rate_limiter.dart';

/// A rate limiter using the token bucket algorithm.
///
/// Tokens are added to the bucket at a fixed rate defined by [refillInterval].
/// Each call to [tryAcquire] or [acquire] consumes one token. When the bucket
/// is empty, requests are either rejected or delayed until a token is available.
class TokenBucket implements RateLimiter {
  /// The maximum number of tokens the bucket can hold.
  final int capacity;

  /// The interval at which a single token is added to the bucket.
  final Duration refillInterval;

  final Map<String, _BucketState> _buckets = {};

  /// Creates a token bucket rate limiter.
  ///
  /// [capacity] is the maximum number of tokens (must be positive).
  /// [refillInterval] is the time between adding each token.
  TokenBucket({
    required this.capacity,
    required this.refillInterval,
  })  : assert(capacity > 0, 'capacity must be positive'),
        assert(
            refillInterval > Duration.zero, 'refillInterval must be positive');

  _BucketState _bucket(String key) {
    return _buckets.putIfAbsent(key, () => _BucketState(capacity));
  }

  void _refill(_BucketState state) {
    final now = DateTime.now();
    final elapsed = now.difference(state.lastRefill);
    final tokensToAdd = elapsed.inMicroseconds ~/ refillInterval.inMicroseconds;
    if (tokensToAdd > 0) {
      state.tokens = (state.tokens + tokensToAdd).clamp(0, capacity);
      state.lastRefill =
          state.lastRefill.add(refillInterval * tokensToAdd);
    }
  }

  @override
  bool tryAcquire({String? key}) {
    final k = key ?? '';
    final state = _bucket(k);
    _refill(state);
    if (state.tokens > 0) {
      state.tokens--;
      return true;
    }
    return false;
  }

  @override
  Future<void> acquire({String? key}) async {
    final k = key ?? '';
    while (!tryAcquire(key: k)) {
      await Future<void>.delayed(refillInterval);
    }
  }

  @override
  void reset({String? key}) {
    if (key != null) {
      _buckets.remove(key);
    } else {
      _buckets.clear();
    }
  }
}

class _BucketState {
  int tokens;
  DateTime lastRefill;

  _BucketState(this.tokens) : lastRefill = DateTime.now();
}
