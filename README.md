# Menimi Backend

Rails API for authentication, recurring tasks, carry-over reconciliation, and web-push summaries.

## Required environment

- `DATABASE_URL`: PostgreSQL connection string.
- `SECRET_KEY_BASE`: Rails secret used by Devise JWT.
- `REDIS_URL`: Redis connection used by Sidekiq.
- `APP_HOSTS`: Comma-separated list of allowed production hostnames. Example: `api.example.com,api.internal.example.com`.
- `CORS_ALLOWED_ORIGINS`: Comma-separated list of allowed frontend origins. Example: `https://app.example.com,https://staging.example.com`.
- `VAPID_SUBJECT`, `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`: Required for web-push delivery.
- `GEMINI_API_KEY`: Required for generating on-demand welcome messages.
- `GEMINI_MODEL`: Optional Gemini model override for welcome messages. Defaults to `gemini-2.5-flash`.

## Local development

- Install gems: `bundle install`
- Create and migrate the database: `bin/rails db:prepare`
- Start the API: `bin/rails server`
- Start jobs: `bundle exec sidekiq -C config/sidekiq.yml`

In non-production environments, CORS defaults to `http://localhost:3000` and `http://127.0.0.1:3000`.

## Production notes

- SSL is enforced in production via `config.force_ssl = true`.
- Host header protection is enabled and requires `APP_HOSTS`.
- CORS is locked down and requires `CORS_ALLOWED_ORIGINS`.
- `/up` remains available for health checks.
- Sidekiq must be running for scheduled carry-over and morning-summary jobs.

## Docker publish

- GitHub Actions runs security scans, RuboCop, and RSpec before building the Docker image.
- On pushes to `master`, the workflow publishes `arthurllbender/menimi-backend:latest` to Docker Hub.
- Add the `DOCKERPASS` repository secret in GitHub before enabling the workflow.

## Verification

- API health check: `GET /up`
- Lint: `bundle exec rubocop -A`
- Tests: `bundle exec rspec`
