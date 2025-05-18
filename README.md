# Sleep Tracker API

A minimal Ruby on Rails 7.2 API-only application that provides:

* Clock-in functionality for tracking user sleep durations
* Follow/unfollow logic between users
* A feed of sleep records from followed users
* Cursor-based pagination
* Memory-based caching (per user feed)

---

## Base Stack

* Ruby 3.3.5
* Rails 7.2.2.1 (API-only mode)
* SQLite (for simplicity, easy to swap for PostgreSQL)
* RSpec for testing

---

## Project Structure

* `User`: has many sleep records, and many followers/followed (via Follow model)
* `SleepRecord`: belongs to a user, stores sleep duration
* `Follow`: join table that stores following relationships

---

## Setup & Run

```bash
git clone <repo>
bundle install
rails db:create db:migrate db:seed
rails server
```

Run tests:

```bash
bundle exec rspec
```

---

## API Endpoints

### Clock-in

* **POST** `/users/:user_id/clock_ins`

  * Body: `{ "duration": 480 }`
  * Creates a sleep record for a user
* **GET** `/users/:user_id/clock_ins?cursor=<optional_cursor>`

  * Returns user's sleep records ordered by created\_at DESC with cursor pagination

### Follow

* **POST** `/users/:id/follow/:followed_id`

  * Makes user `id` follow user `followed_id`

### Unfollow

* **DELETE** `/users/:id/follow/:followed_id`

  * Removes the follow relationship

### Feed

* **GET** `/users/:id/feed?cursor=<optional_cursor>`

  * Returns all sleep records from users that the given user follows
  * Ordered by `created_at DESC`
  * Uses per-user memory cache

---

## Technical Highlights

### Cursor Pagination

* Stable pagination using `(created_at, id)`
* More consistent than offset under high data churn

### Memory Caching

* Uses `Rails.cache` to store per-user feed results
* Cached for 5 minutes
* Cache invalidated on follow/unfollow

### Lightweight & Fast

* No authentication
* Designed for internal trusted usage or prototyping

---

## Scaling Strategies (Suggestions for Growth)

As the system scales to support high data volumes and concurrent traffic:

### 1. **Database**

* Add PostgreSQL for better concurrency & JSONB support
* Add indexes on: `follows`, `sleep_records(user_id, created_at)`

### 2. **Caching**

* Move from memory cache to Redis (to support distributed cache across nodes)
* Use `Rails.cache.delete_matched` or versioned cache keys for smarter invalidation

### 3. **API Optimization**

* Add rate-limiting with Rack::Attack
* Use background jobs (e.g., Sidekiq) for expensive operations like follower notifications

### 4. **Authentication**

* Add JWT/Clerk/Auth0 if this becomes a public API

### 5. **Monitoring & Observability**

* Add request logging, slow query detection
* Instrument sleep activity and feed popularity

---

## 👨‍💻 Created by

**Abdul Salam**
GitHub: [@abdulsalam01](https://github.com/abdulsalam01)