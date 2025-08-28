# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-04-11

### Added
- `retryAfter()` method on all rate limiters that returns the duration until the next permit becomes available

### Fixed
- Updated package description to include fixed window algorithm
- `FixedWindow` now uses `implements RateLimiter` for consistency with other implementations

## [0.3.0] - 2026-04-05

### Added
- `isExhausted()` method on all rate limiters that returns `true` when no permits remain

## [0.2.0] - 2026-04-04

### Added
- `FixedWindow` rate limiter with simple window-based counting
- Optional `timeout` parameter on `acquire()` that throws `TimeoutException`
- `stats()` method for tracking total, allowed, and rejected request counts
- `availablePermits()` to check remaining capacity without consuming a permit
- `RateLimiterStats` class for structured statistics access

## [0.1.0] - 2026-04-03

### Added
- Initial release
- Token bucket rate limiter with configurable capacity and refill interval
- Sliding window rate limiter with configurable max requests and window duration
- Per-key rate limiting support for both algorithms
- Async `acquire` method that waits until a permit is available
- Non-blocking `tryAcquire` method for immediate checks
- `reset` method to clear rate limiter state
