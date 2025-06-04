# RateLimiter

A Ruby implementation of a **per-user, sliding window rate limiter** designed to efficiently enforce API request limits with O(1) operations and high scalability.

---

## Problem Statement

Each `user_id` is allowed a maximum number of requests within a rolling time period. For example:

> “Each user is allowed 3 requests per 30 seconds.”

This implementation ensures correct enforcement using a hash of timestamp queues and includes optional memory hygiene utilities for production-grade use.

---

## Features

- Sliding window algorithm (not fixed buckets)
- Per-user state for isolated, accurate enforcement
- O(1) operations using a hash + timestamp queue
- Optional memory cleanup for inactive users
- Fully tested with RSpec

---

## Usage

```ruby
limiter = RateLimiter.new(30, 3)

limiter.allow_request?(Time.now.to_i, 42)
# => true or false
```

### Parameters

`time_window`:
- Type: Integer
- Description: Number of seconds to track (e.g. 30)

`max_requests`:
- Type: Integer
- Description: Max requests allowed within that period

---

## Design Decisions

### Why Per-User State?

- Matches the problem requirements (user-scoped limits)
- Enables true request isolation
- Efficient and scalable to millions of users

### Why Arrays?

- Simpler and idiomatic in Ruby
- Queues are very short (≤ 3 elements) so `Array#shift` performance impact is negligible here

---

## Memory Management (Optional)

Long-lived systems can use:

```ruby
limiter.prune_inactive_users!(Time.now.to_i)
```

To periodically clean up users whose activity has fully expired. This is optional but recommended at scale.

---

## Testing

Run specs using:

```bash
bundle exec rspec
```

Test coverage includes:
- Basic windowing behavior
- Per-user independence
- Prompt-provided sample scenario
- Memory pruning logic

---

## Limitations & Future Improvements

### 1. **In-Memory Only**

State is stored locally using a hash:
- This is simple and fast
- Doesn’t scale across distributed nodes

### 2. **O(n) Array Shift**

Ruby's `Array#shift` has O(n) worst-case complexity, but this is acceptable for very small queues (max 3 entries per user).
Performance can be improved using deques if needed.

### 3. **Manual Pruning**

Inactive users remain in memory unless explicitly pruned. A `prune_inactive_users!` method is provided for periodic cleanup.

### Other Potential Future Enhancements

- Redis adapter for shared/distributed rate limits
- Tiered rate limit rules (e.g., admins vs guests)
- Built-in TTL expiration
- Telemetry (rate-limited count, peak usage)
