import 'package:philiprehberger_rate_limiter/rate_limiter.dart';
import 'package:test/test.dart';

void main() {
  group('TokenBucket', () {
    test('allows requests up to capacity', () {
      final limiter = TokenBucket(
        capacity: 3,
        refillInterval: Duration(seconds: 1),
      );
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isTrue);
    });

    test('blocks requests when bucket is empty', () {
      final limiter = TokenBucket(
        capacity: 1,
        refillInterval: Duration(seconds: 1),
      );
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isFalse);
    });

    test('refills tokens over time', () async {
      final limiter = TokenBucket(
        capacity: 1,
        refillInterval: Duration(milliseconds: 50),
      );
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isFalse);
      await Future<void>.delayed(Duration(milliseconds: 100));
      expect(limiter.tryAcquire(), isTrue);
    });

    test('per-key isolation', () {
      final limiter = TokenBucket(
        capacity: 1,
        refillInterval: Duration(seconds: 1),
      );
      expect(limiter.tryAcquire(key: 'a'), isTrue);
      expect(limiter.tryAcquire(key: 'a'), isFalse);
      expect(limiter.tryAcquire(key: 'b'), isTrue);
    });

    test('reset clears state', () {
      final limiter = TokenBucket(
        capacity: 1,
        refillInterval: Duration(seconds: 1),
      );
      expect(limiter.tryAcquire(key: 'a'), isTrue);
      expect(limiter.tryAcquire(key: 'a'), isFalse);
      limiter.reset(key: 'a');
      expect(limiter.tryAcquire(key: 'a'), isTrue);
    });

    test('acquire waits for token', () async {
      final limiter = TokenBucket(
        capacity: 1,
        refillInterval: Duration(milliseconds: 50),
      );
      expect(limiter.tryAcquire(), isTrue);
      final stopwatch = Stopwatch()..start();
      await limiter.acquire();
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
    });
  });

  group('SlidingWindow', () {
    test('allows requests up to max', () {
      final limiter = SlidingWindow(
        maxRequests: 3,
        window: Duration(seconds: 1),
      );
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isTrue);
    });

    test('blocks requests when window is full', () {
      final limiter = SlidingWindow(
        maxRequests: 1,
        window: Duration(seconds: 1),
      );
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isFalse);
    });

    test('allows requests after window expires', () async {
      final limiter = SlidingWindow(
        maxRequests: 1,
        window: Duration(milliseconds: 50),
      );
      expect(limiter.tryAcquire(), isTrue);
      expect(limiter.tryAcquire(), isFalse);
      await Future<void>.delayed(Duration(milliseconds: 100));
      expect(limiter.tryAcquire(), isTrue);
    });

    test('per-key isolation', () {
      final limiter = SlidingWindow(
        maxRequests: 1,
        window: Duration(seconds: 1),
      );
      expect(limiter.tryAcquire(key: 'a'), isTrue);
      expect(limiter.tryAcquire(key: 'a'), isFalse);
      expect(limiter.tryAcquire(key: 'b'), isTrue);
    });

    test('reset clears state', () {
      final limiter = SlidingWindow(
        maxRequests: 1,
        window: Duration(seconds: 1),
      );
      expect(limiter.tryAcquire(key: 'a'), isTrue);
      expect(limiter.tryAcquire(key: 'a'), isFalse);
      limiter.reset(key: 'a');
      expect(limiter.tryAcquire(key: 'a'), isTrue);
    });

    test('acquire waits for window to expire', () async {
      final limiter = SlidingWindow(
        maxRequests: 1,
        window: Duration(milliseconds: 50),
      );
      expect(limiter.tryAcquire(), isTrue);
      final stopwatch = Stopwatch()..start();
      await limiter.acquire();
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
    });
  });
}
