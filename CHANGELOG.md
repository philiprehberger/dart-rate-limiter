# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-04-03

### Added
- Initial release
- Token bucket rate limiter with configurable capacity and refill interval
- Sliding window rate limiter with configurable max requests and window duration
- Per-key rate limiting support for both algorithms
- Async `acquire` method that waits until a permit is available
- Non-blocking `tryAcquire` method for immediate checks
- `reset` method to clear rate limiter state
