import 'package:philiprehberger_rate_limiter/rate_limiter.dart';

void main() async {
  // Token bucket: allow 3 requests, refill one token every 200ms
  final bucket = TokenBucket(
    capacity: 3,
    refillInterval: Duration(milliseconds: 200),
  );

  print('--- Token Bucket ---');
  for (var i = 1; i <= 5; i++) {
    final allowed = bucket.tryAcquire();
    print('Request $i: ${allowed ? "allowed" : "rate-limited"}');
  }

  // Wait for refill and try again
  await Future<void>.delayed(Duration(milliseconds: 500));
  print('After waiting: ${bucket.tryAcquire() ? "allowed" : "rate-limited"}');

  // Sliding window: allow 2 requests per 500ms window
  final window = SlidingWindow(
    maxRequests: 2,
    window: Duration(milliseconds: 500),
  );

  print('\n--- Sliding Window ---');
  for (var i = 1; i <= 4; i++) {
    final allowed = window.tryAcquire();
    print('Request $i: ${allowed ? "allowed" : "rate-limited"}');
  }

  // Async acquire waits until a permit is available
  print('\nWaiting for permit...');
  await window.acquire();
  print('Permit acquired!');

  // Per-key rate limiting
  final perUser = TokenBucket(
    capacity: 1,
    refillInterval: Duration(seconds: 1),
  );

  print('\n--- Per-Key Rate Limiting ---');
  print('User A: ${perUser.tryAcquire(key: "user-a") ? "allowed" : "blocked"}');
  print('User A: ${perUser.tryAcquire(key: "user-a") ? "allowed" : "blocked"}');
  print('User B: ${perUser.tryAcquire(key: "user-b") ? "allowed" : "blocked"}');

  // Composite: enforce multiple tiers at once
  final composite = CompositeRateLimiter([
    TokenBucket(capacity: 5, refillInterval: Duration(seconds: 1)),
    SlidingWindow(maxRequests: 100, window: Duration(minutes: 1)),
  ]);

  print('\n--- Composite Rate Limiter ---');
  for (var i = 1; i <= 7; i++) {
    final allowed = composite.tryAcquire();
    print('Request $i: ${allowed ? "allowed" : "rate-limited"}');
  }
}
