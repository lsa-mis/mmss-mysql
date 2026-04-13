# MMSS — Camp Application & Enrollment System

[View performance data on Skylight](https://www.skylight.io/app/applications/zrIB2wxUUwFF)

A Ruby on Rails application for managing summer camp applications, enrollments, courses, financial aid, recommendations, and payments. The system supports applicants, faculty, and administrators with separate interfaces and workflows.

---

## Table of Contents

- [Features](#features)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [Running the Test Suite](#running-the-test-suite)
- [Deployment](#deployment)
- [Project Structure](#project-structure)
- [License & Support](#license--support)

---

## Features

- **Applicant portal** — Registration, applicant details, enrollments, personal statements, course preferences, recommendations, financial aid requests, travel information, and payments
- **Camp configuration** — Per-year settings: application open/close dates, priority and materials deadlines, offer/reject/waitlist letters, application fees
- **Sessions & courses** — Camp occurrences (sessions), activities, courses with faculty and capacity; session assignments and course assignments with waitlisting
- **Financial aid** — Aid requests, amounts, status, and payment deadlines
- **Recommendations** — Request and upload recommendation letters; email-based workflow
- **Payments** — Payment flows and receipts (integration with external payment provider)
- **Admin (ActiveAdmin)** — Full CRUD and reporting: demographics, camp configs, enrollments, reports (complete applications, waitlist, enrolled with addresses, course assignments, demographic reports, etc.)
- **Faculty interface** — Faculty login and student list/student page views
- **Maintenance mode** — Turnout-based maintenance page support for deployments

---

## Technology Stack


| Layer            | Technology                                                       |
| ---------------- | ---------------------------------------------------------------- |
| **Runtime**      | Ruby 3.3.4                                                       |
| **Framework**    | Rails 7.2.3.1                                                    |
| **Database**     | MySQL 8 (mysql2 gem), utf8mb4                                    |
| **Auth**         | Devise (users, admins, faculties)                                |
| **Admin**        | ActiveAdmin 3.x                                                  |
| **Server**       | Puma 5.6                                                         |
| **Frontend**     | Webpacker 5, Turbolinks, Stimulus, Tailwind CSS, Flatpickr       |
| **File storage** | Active Storage (local disk / Google Cloud Storage in production) |
| **Monitoring**   | Skylight, Sentry                                                 |
| **Deployment**   | Capistrano 3, asdf                                               |


---

## Prerequisites

- **Ruby** 3.3.4 (recommended: [asdf](https://asdf-vm.com/) or rbenv)
- **MySQL** 8.x (with OpenSSL available for the `mysql2` gem)
- **Node.js** (for Webpacker; LTS version recommended)
- **Bundler** 2.x
- **Git**

### MySQL and mysql2 gem

On macOS with Homebrew MySQL you may need to pass include/lib paths when installing the mysql2 gem:

```bash
# Homebrew MySQL (example)
gem install mysql2 -v '0.5.6' -- --with-mysql-dir=/opt/homebrew/opt/mysql --with-mysql-lib=/opt/homebrew/opt/mysql/lib --with-mysql-include=/opt/homebrew/opt/mysql/include
```

---

## Installation

1. **Clone the repository**
  ```bash
   git clone git@github.com:lsa-mis/mmss-mysql.git
   cd mmss-mysql
  ```
2. **Install Ruby dependencies**
  ```bash
   bundle install
  ```
3. **Install JavaScript dependencies**
  ```bash
   yarn install
   # or: npm install
  ```
4. **Create and configure the database** (see [Configuration](#configuration))
  ```bash
   # Set LOCAL_MYSQL_DATABASE_PASSWORD (see below), then:
   bin/rails db:create
   bin/rails db:schema:load
   # Optionally: bin/rails db:seed
  ```
5. **Prepare Rails credentials and config** (see [Configuration](#configuration))

---

## Configuration

### Database

- **Development / Test**  
Set the MySQL password via environment:
  ```bash
  export LOCAL_MYSQL_DATABASE_PASSWORD='your_local_mysql_password'
  ```
  Default DB names: `mmss-mysql_development`, `mmss-mysql_test`.  
  Edit `config/database.yml` if you use a different user or host.
- **Production**  
Production uses credentials or environment variables for MySQL:
  - `Rails.application.credentials.dig(:mysql, :prod_user)` or `MYSQL_PROD_USER`
  - `Rails.application.credentials.dig(:mysql, :prod_password)` or `MYSQL_PROD_PASSWORD`
  - `Rails.application.credentials.dig(:mysql, :prod_servername)` or `MYSQL_PROD_HOST`
  - `Rails.application.credentials.dig(:mysql, :prod_sslca)` or `MYSQL_PROD_SSLCA`

### Rails credentials

Use `bin/rails credentials:edit` to set (among others):

- `mysql` — production DB user, password, host, sslca
- `skylight` — Skylight authentication (production/staging)
- Any other secrets (e.g., payment provider, mailer)

Keep `config/master.key` secure and do not commit it. In deployment it is linked from the server’s shared config.

### File storage (Active Storage)

- **Development / Test**  
Uses local disk (`storage/`, `tmp/storage`).
- **Production**  
Configured for Google Cloud Storage (GCS). A GCS keyfile is expected. Bucket and project are set in `config/storage.yml`.

### Optional services

- **Skylight** — Set `SKYLIGHT_AUTHENTICATION` or use credentials for production/staging.
- **Sentry** — Configure in `config/initializers/sentry.rb` and via Sentry DSN.
- **Redis** — Optional; Action Cable uses `REDIS_URL` (default `redis://localhost:6379/1`).

---

## Running the Application

1. **Start MySQL** (if not running as a service).
2. **Start the Rails server**
  ```bash
   bin/rails server
  ```
   Default: [http://localhost:3000](http://localhost:3000)
3. **Start Webpack dev server** (for asset compilation in development)
  ```bash
   bin/webpack-dev-server
  ```
4. **Useful URLs (development)**
  - Root: `/`
  - Admin: `/admin` (Devise admin login)
  - Faculty: `/faculty`, `/faculty_login`
  - Letter opener (development and staging): `/letter_opener` (on staging, protect with HTTP basic auth env vars or network rules)

---

## Running the Test Suite

- **RSpec**
  ```bash
  bundle exec rspec
  ```
  Ensure the test database exists and is migrated:
  ```bash
  RAILS_ENV=test bin/rails db:create db:schema:load
  ```
- **Code style (Standard Ruby)**
  ```bash
  bundle exec standardrb
  ```

---

## Deployment

### Production (Capistrano + asdf)

- **Repo**: `git@github.com:lsa-mis/mmss-mysql.git`
- **Branch**: `main`
- **Server**: `config/deploy/production.rb` (e.g. `mathmmssapp2.miserver.it.umich.edu`), roles: app, db, web.
- **Linked files** (must exist in shared config on the server):  
`config/puma.rb`, `config/nginx.conf`, `config/master.key`, `config/lsa-was-base-c096c776ead3.json`, `mysql/InCommon.CA.crt`

```bash
bundle exec cap production deploy
bundle exec cap production deploy:upload
bundle exec cap production puma:restart
bundle exec cap production puma:stop
bundle exec cap production maintenance:start
bundle exec cap production maintenance:stop
```

Before deploy, `deploy:check_revision` ensures local HEAD matches `origin/main`.

### Staging (Hatchbox + DigitalOcean)

Use a **separate Hatchbox app** (or equivalent) with the `**staging` git branch** and a **deploy webhook** so merges to `staging` trigger a deploy. Set `**RAILS_ENV=staging`** in the Hatchbox environment so Rails loads `[config/environments/staging.rb](config/environments/staging.rb)` (local Active Storage, `letter_opener_web`, no GCS keyfile).

**Suggested environment variables**


| Variable                                                                      | Purpose                                                                                                                                                                        |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `RAILS_ENV`                                                                   | `staging`                                                                                                                                                                      |
| `RAILS_MASTER_KEY`                                                            | Decrypts credentials (use staging-specific credentials if you run `bin/rails credentials:edit --environment staging`)                                                          |
| `SECRET_KEY_BASE`                                                             | Hatchbox often sets this; required for sessions                                                                                                                                |
| `DATABASE_URL`                                                                | MySQL URL from Hatchbox / DigitalOcean (e.g. `mysql2://user:pass@host:3306/dbname`) — **or** omit and set `STAGING_DATABASE_`* in `[config/database.yml](config/database.yml)` |
| `STAGING_MAILER_HOST`                                                         | Public hostname for mailer URLs (e.g. `staging.example.edu`)                                                                                                                   |
| `STAGING_MAILER_PROTOCOL`                                                     | Usually `https`                                                                                                                                                                |
| `STAGING_ALLOWED_HOSTS`                                                       | Comma-separated hosts if `ActionDispatch::HostAuthorization` blocks the real hostname                                                                                          |
| `LETTER_OPENER_WEB_HTTP_BASIC_USER` / `LETTER_OPENER_WEB_HTTP_BASIC_PASSWORD` | Optional HTTP basic auth for `/letter_opener`                                                                                                                                  |
| `NODE_OPTIONS`                                                                | If asset precompile fails on OpenSSL, use `--openssl-legacy-provider` (same as production builds)                                                                              |
| `RAILS_SERVE_STATIC_FILES`                                                    | Set if the app serves static files without nginx in front                                                                                                                      |


The root `[Procfile](Procfile)` runs Puma with `[config/puma.default.rb](config/puma.default.rb)` (binds to `$PORT`). For local **web + webpack**, use `foreman start -f Procfile.dev`.

---

## Project Structure


| Path                        | Purpose                                                                                 |
| --------------------------- | --------------------------------------------------------------------------------------- |
| `app/`                      | Models, controllers, views, mailers, helpers, ActiveAdmin config                        |
| `config/`                   | Application, routes, environments, initializers, deploy                                 |
| `Procfile` / `Procfile.dev` | Puma on `$PORT` for PaaS; local Rails + webpack watcher                                 |
| `config/puma.default.rb`    | Portable Puma (Hatchbox / DO); production Capistrano still uses linked `config/puma.rb` |
| `db/`                       | Schema, migrations, seeds                                                               |
| `lib/capistrano/tasks/`     | Custom Capistrano tasks                                                                 |
| `spec/`                     | RSpec tests and support                                                                 |
| `config/storage.yml`        | Active Storage backends (local, GCS)                                                    |


### Main domain concepts

- **User** — Applicant account (Devise).
- **ApplicantDetail** — Demographics, contact, parent info, etc.
- **Enrollment** — Per-year application: high school, statement, status, offer status, session assignments, course preferences, recommendations, financial aid, travel.
- **CampConfiguration** — Camp year and dates (application open/close, priority, materials due, etc.).
- **CampOccurrence** — A session (date range); has activities and courses.
- **Course** — Course within a session; course preferences and course assignments (with waitlist).
- **SessionAssignment** — Enrollment in a session; accept/decline offers.
- **FinancialAid**, **Recommendation**, **Payment**, **Travel** — Supporting enrollment data.

---

## License & Support

Proprietary — LSA MIS. For access, deployment, or support, contact the maintaining team.