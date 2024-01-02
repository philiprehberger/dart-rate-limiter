# philiprehberger_rate_limiter

[![Tests](https://github.com/philiprehberger/dart-rate-limiter/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/dart-rate-limiter/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/philiprehberger_rate_limiter.svg)](https://pub.dev/packages/philiprehberger_rate_limiter)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/dart-rate-limiter)](https://github.com/philiprehberger/dart-rate-limiter/commits/main)

Token bucket and sliding window rate limiting for async operations

## Requirements

- Dart >= 3.6

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  philiprehberger_rate_limiter: ^0.1.0
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

### Per-Key Rate Limiting

Both algorithms support per-key rate limiting for multi-tenant scenarios.

```dart
final limiter = TokenBucket(
  capacity: 5,
  refillInterval: Duration(seconds: 1),
);

limiter.tryAcquire(key: 'user-123');
limiter.tryAcquire(key: 'user-456');
limiter.reset(key: 'user-123');
```

## API

| Method | Description |
|--------|-------------|
| `TokenBucket({capacity, refillInterval})` | Create a token bucket rate limiter |
| `SlidingWindow({maxRequests, window})` | Create a sliding window rate limiter |
| `RateLimiter.tryAcquire({key})` | Try to acquire a permit, returns `true` if allowed |
| `RateLimiter.acquire({key})` | Acquire a permit, waiting if necessary |
| `RateLimiter.reset({key})` | Reset state for a key, or all keys if omitted |

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
