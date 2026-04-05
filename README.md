# philiprehberger_rate_limiter

[![Tests](https://github.com/philiprehberger/dart-rate-limiter/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/dart-rate-limiter/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/philiprehberger_rate_limiter.svg)](https://pub.dev/packages/philiprehberger_rate_limiter)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/dart-rate-limiter)](https://github.com/philiprehberger/dart-rate-limiter/commits/main)

Token bucket, sliding window, and fixed window rate limiting for async operations

## Requirements

- Dart >= 3.6

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  philiprehberger_rate_limiter: ^0.3.0
```

Then run:

```bash
dart pub get
```

## Usage

```dart
import 'package:philiprehberger_rate_limiter/philiprehberger_rate_limiter.dart';

final limiter = TokenBucket(
  capacity: 10,
  refillInterval: Duration(seconds: 1),
);

if (limiter.tryAcquire()) {
  // Request allowed
}
```

### Token Bucket

The token bucket algorithm maintains a bucket of tokens that refills at a fixed rate. Each request consumes one token.

```dart
final bucket = TokenBucket(
  capacity: 5,
  refillInterval: Duration(milliseconds: 200),
);

// Non-blocking check
if (bucket.tryAcquire()) {
  print('Allowed');
} else {
  print('Rate limited');
}

// Async wait until a token is available
await bucket.acquire();
```

### Sliding Window

The sliding window algorithm tracks request timestamps and limits the number of requests within a rolling time window.

```dart
final window = SlidingWindow(
  maxRequests: 100,
  window: Duration(minutes: 1),
);

if (window.tryAcquire()) {
  print('Allowed');
}

// Wait until the window has room
await window.acquire();
```

### Fixed Window

The fixed window algorithm allows up to a set number of requests within each fixed time interval. The counter resets completely when the window expires.

```dart
final limiter = FixedWindow(
  maxRequests: 10,
  window: Duration(seconds: 1),
);

if (limiter.tryAcquire()) {
  print('Allowed');
}

// Wait until the next window
await limiter.acquire();
```

### Per-Key Rate Limiting

All algorithms support per-key rate limiting for multi-tenant scenarios.

```dart
final limiter = TokenBucket(
  capacity: 5,
  refillInterval: Duration(seconds: 1),
);

limiter.tryAcquire(key: 'user-123');
limiter.tryAcquire(key: 'user-456');
limiter.reset(key: 'user-123');
```

### Statistics

Track request counts with the `stats()` method available on all rate limiters.

```dart
final limiter = TokenBucket(
  capacity: 5,
  refillInterval: Duration(seconds: 1),
);

limiter.tryAcquire();
limiter.tryAcquire();

final s = limiter.stats();
print('Total: ${s.totalRequests}');
print('Allowed: ${s.allowedRequests}');
print('Rejected: ${s.rejectedRequests}');
```

### Available Permits

Check remaining capacity without consuming a permit.

```dart
final limiter = FixedWindow(
  maxRequests: 10,
  window: Duration(seconds: 1),
);

print(limiter.availablePermits()); // 10
limiter.tryAcquire();
print(limiter.availablePermits()); // 9
```

### Exhaustion Check

Quickly check whether a rate limiter has any permits left.

```dart
final limiter = TokenBucket(
  capacity: 1,
  refillInterval: Duration(seconds: 1),
);

print(limiter.isExhausted()); // false
limiter.tryAcquire();
print(limiter.isExhausted()); // true
```

### Acquire with Timeout

Pass a `timeout` to `acquire()` to throw a `TimeoutException` if a permit is not available in time.

```dart
import 'dart:async';

try {
  await limiter.acquire(timeout: Duration(seconds: 5));
} on TimeoutException {
  print('Could not acquire permit in time');
}
```

## API

| Method | Description |
|--------|-------------|
| `TokenBucket({capacity, refillInterval})` | Create a token bucket rate limiter |
| `SlidingWindow({maxRequests, window})` | Create a sliding window rate limiter |
| `FixedWindow({maxRequests, window})` | Create a fixed window rate limiter |
| `RateLimiter.tryAcquire({key})` | Try to acquire a permit, returns `true` if allowed |
| `RateLimiter.acquire({key, timeout})` | Acquire a permit, waiting if necessary; throws `TimeoutException` on timeout |
| `RateLimiter.reset({key})` | Reset state for a key, or all keys if omitted |
| `RateLimiter.stats({key})` | Get request statistics (total, allowed, rejected) |
| `RateLimiter.availablePermits({key})` | Check remaining permits without consuming one |
| `RateLimiter.isExhausted({key})` | Returns `true` when no permits are available |

## Development

```bash
dart pub get
dart analyze --fatal-infos
dart test
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/dart-rate-limiter)

🐛 [Report issues](https://github.com/philiprehberger/dart-rate-limiter/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/dart-rate-limiter/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
