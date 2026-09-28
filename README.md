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
- **Admin** — Plain Rails `Admin::` MVC at `/admin` (dashboard, 26 resources in four menu groups, 18 CSV reports, comments on records, CSV exports with a formula-injection guard); `/legacy_admin` bookmarks redirect to `/admin`
- **Faculty interface** — Faculty login and student list/student page views
- **Maintenance mode** — Rack middleware (`lib/middleware/maintenance_mode.rb`) serves `public/maintenance.html` while `tmp/maintenance.yml` exists on the server

---

## Technology Stack


| Layer            | Technology                                                       |
| ---------------- | ---------------------------------------------------------------- |
| **Runtime**      | Ruby 4.0.6 (`.ruby-version`, `.tool-versions`, `Gemfile`), Bundler 4 |
| **Framework**    | Rails 8.1 (`config.load_defaults 8.1`); no Node.js anywhere      |
| **Database**     | MySQL 8 (mysql2 gem), utf8mb4                                    |
| **Auth**         | Devise (users, admins, faculties); admins sign in at `/admin/login` |
| **Admin**        | `Admin::` namespace (`Admin::BaseController`, per-resource filters, scopes, Pagy pagination, batch actions, `Admin::CsvExport`, `Admin::Reports` SQL reports, `Admin::Comment`) |
| **Server**       | Puma 8 (systemd notify built in)                                 |
| **Assets**       | Propshaft (digests + serves `app/assets/builds`, `app/assets/images`, importmap modules), importmap-rails, Hotwire (Turbo Drive + Stimulus), Tailwind CSS 4 (tailwindcss-rails; `tailwind.css` + `admin.css` bundles), Flatpickr |
| **Money**        | money-rails 3 / money 7 (`monetize` columns, USD)                |
| **File storage** | Active Storage (local disk / Google Cloud Storage in production) |
| **Monitoring**   | Skylight, Sentry                                                 |
| **Testing / CI** | RSpec, FactoryBot, Capybara + Selenium; GitHub Actions (`.github/workflows/ci.yml`) |
| **Deployment**   | Production: Capistrano 3 + asdf on a UM host. Staging: Hatchbox (DigitalOcean) |


---

## Prerequisites

- **Ruby** 4.0.6 (recommended: [asdf](https://asdf-vm.com/) or rbenv; `.ruby-version` and `.tool-versions` pin it)
- **MySQL** 8.x (with OpenSSL available for the `mysql2` gem)
- **Bundler** 4.x (ships with Ruby 4.0; `Gemfile.lock` records the version)
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
3. **Create and configure the database** (see [Configuration](#configuration))
  ```bash
   # Set LOCAL_MYSQL_DATABASE_PASSWORD (see below), then:
   bin/rails db:create
   bin/rails db:schema:load
   # Optionally: bin/rails db:seed
  ```
4. **Prepare Rails credentials and config** (see [Configuration](#configuration))

No Node.js or Yarn is required: JavaScript is served through import maps
(`config/importmap.rb`, `app/javascript/`, vendored packages in
`vendor/javascript/`) and Tailwind is compiled by the `tailwindcss-ruby`
standalone binary that ships with the `tailwindcss-rails` gem.

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

### Hosts, SSL and health checks (production and staging)

Both deployed environments run behind a TLS-terminating proxy, so `config.assume_ssl` and
`config.force_ssl` are on, and `ActionDispatch::HostAuthorization` only answers the public hostname:
`mmss-registration.math.lsa.umich.edu` (production) and `mmss-registration-staging.lsa.umich.edu`
(staging). Any other `Host` header gets a 403 and a `Blocked hosts:` log line. To serve additional
names (the cluster's internal node names, a load-balancer IP, a Hatchbox preview host) set

```bash
RAILS_ALLOWED_HOSTS=mathmmssapp2.miserver.it.umich.edu,.internal.umich.edu   # comma-separated; leading dot = any subdomain
```

in the service environment and restart Puma; no deploy is needed (`lib/allowed_hosts.rb`). `/up`
(the Rails health check) is exempt and is served for any host, so monitors can address the node
directly. Staging also still reads the legacy `STAGING_ALLOWED_HOSTS` variable.

### Optional services

- **Skylight** — Set `SKYLIGHT_AUTHENTICATION` or use credentials for production/staging.
- **Sentry** — DSN from credentials (`sentry.dsn`); options in `config/initializers/sentry.rb`.
- **Redis** — Only referenced by `config/cable.yml` in production (`REDIS_URL`); the app defines no
  Action Cable channels, so nothing connects unless one is added.

---

## Running the Application

1. **Start MySQL** (if not running as a service).
2. **Start the Rails server and the Tailwind watcher**
  ```bash
   bin/dev
  ```
   `bin/dev` runs `Procfile.dev` through foreman (installed on first use):
   `bin/rails server` on port 3000 plus the two Tailwind watchers
   (`tailwindcss:watch` for the applicant/faculty bundle, `tailwindcss:watch:admin`
   for `admin.css`), which rebuild `app/assets/builds/*.css` whenever
   `app/assets/tailwind/` or the views change. Without the watchers, run
   `bin/rails tailwindcss:build` once after editing styles and start
   `bin/rails server` on its own.
   Default: [http://localhost:3000](http://localhost:3000)
3. **Useful URLs (development)**
  - Root: `/`
  - Admin: `/admin` (login at `/admin/login`; seed admin `admin@example.com` / `passwordpassword` from `db/seeds.rb`)
  - Faculty: `/faculty`, `/faculty_login`
  - Letter opener (development and staging): `/letter_opener` (on staging, protect with HTTP basic auth env vars or network rules)

---

## Running the Test Suite

- **RSpec**
  ```bash
  bundle exec rspec
  ```
  Ensure the test database exists and is migrated, and that the Tailwind
  build exists (request and system specs render the layouts):
  ```bash
  RAILS_ENV=test bin/rails db:create db:schema:load
  RAILS_ENV=test bin/rails tailwindcss:build
  ```
  System specs (`spec/system`) drive headless Chrome through Selenium
  (`SHOW_BROWSER=1` for a visible browser). CI runs everything except the
  system specs on every pull request against a MySQL 8 service
  (`.github/workflows/ci.yml`). Conventions and layout: [TESTING_STRATEGY.md](TESTING_STRATEGY.md);
  production log forensics: [LOG_INVESTIGATION_GUIDE.md](LOG_INVESTIGATION_GUIDE.md).
- **Code style (Standard Ruby)**
  ```bash
  bundle exec standardrb          # not enforced in CI yet; see TESTING_STRATEGY.md
  ```

---

## Deployment

Work lands on `staging` (pull requests, CI), is verified on the staging host, and is then promoted
to `main`, which production deploys from.

### Production (Capistrano + asdf, UM cluster)

- **Repo**: `git@github.com:lsa-mis/mmss-mysql.git`
- **Branch**: `main`
- **Server**: `config/deploy/production.rb` (e.g. `mathmmssapp2.miserver.it.umich.edu`), roles: app, db, web; app lives in `/home/deployer/apps/mmss-mysql`.
- **Linked files** (must exist in shared config on the server):  
`config/puma.rb`, `config/nginx.conf`, `config/master.key`, `config/lsa-was-base-c096c776ead3.json`, `mysql/InCommon.CA.crt`

Deploy steps:

```bash
# 1. once per Ruby bump, on the host as deployer (see below)
asdf install ruby 4.0.6 && asdf reshim ruby

# 2. from your machine, with main checked out and pushed
bundle exec cap production deploy          # check_revision, bundle, assets:precompile, db:migrate, puma:restart
bundle exec cap production deploy:upload   # only when a linked config file changed (puma.rb, nginx.conf, master.key, GCS key, CA cert)

# operations
bundle exec cap production puma:restart
bundle exec cap production puma:stop
bundle exec cap production maintenance:start   # tmp/maintenance.yml from config/maintenance_template.yml
bundle exec cap production maintenance:stop
bundle exec cap production rubygems:update
```

Before deploy, `deploy:check_revision` ensures local HEAD matches `origin/main`. Migrations run
through capistrano-rails (`deploy:migrate`, db role) whenever `db/migrate` changed. Puma's
environment (systemd unit, see `config/puma_prod.service`) is where `RAILS_ALLOWED_HOSTS`,
`RAILS_LOG_LEVEL` and `RAILS_MAX_THREADS` go.

The host provides Ruby through asdf (`capistrano-asdf` reads `.tool-versions`, and
`config/deploy.rb` points `bundle`/`ruby` at `/home/deployer/.asdf/shims`). Install the
Ruby version pinned in `.tool-versions` on the host before deploying a release that bumps
it, e.g. for 4.0.6:

```bash
asdf install ruby 4.0.6        # needs libyaml-dev, libssl-dev, zlib1g-dev, libffi-dev, libmysqlclient-dev
asdf reshim ruby
```

`debug:print_ruby_version` runs before `bundler:install` and prints the Ruby the release
resolved to, so a missing install fails early.

Assets are compiled on the server by capistrano-rails (`bin/rails assets:precompile`),
which runs `tailwindcss:build` (both bundles, via the `tailwindcss-ruby` standalone
binary) and then Propshaft copies the digested files to `public/assets` (manifest:
`public/assets/.manifest.json`, which capistrano-rails 1.7 backs up and restores).
No Node.js, Yarn or `NODE_OPTIONS` are needed on the host. Compiled assets live in
the linked `public/assets` directory.

`maintenance:start` uploads `config/maintenance_template.yml` to `tmp/maintenance.yml` on the server; while that file exists the `MaintenanceMode` middleware answers every request routed through Rails (except `allowed_paths` / `allowed_ips`) with `public/maintenance.html`; static files that nginx serves directly from `public/` via `try_files` never reach the middleware (same as with turnout), the `response_code` (default 503) and a `Retry-After` header. `maintenance:stop` removes the file. Edit the template's `reason`, `allowed_ips`, etc. before starting.

### Staging (Hatchbox + DigitalOcean)

Hatchbox builds the app from the repository: it reads `.ruby-version`, runs `bundle install` and
`bin/rails assets:precompile` (Tailwind via the bundled standalone binary, then Propshaft), and runs
the release command. Set it up as a **separate Hatchbox app** on the **`staging` branch** with a
**deploy webhook**, so every merge to `staging` deploys, and:

1. `RAILS_ENV=staging` so Rails loads [config/environments/staging.rb](config/environments/staging.rb)
   (local Active Storage, `letter_opener_web`, no GCS keyfile, HTTP basic auth on `/letter_opener`).
2. Release command: `bin/rails db:migrate`.
3. Process: the root [Procfile](Procfile) (`bundle exec puma -C config/puma.default.rb`, binds `$PORT`).
4. The environment variables below.

**Environment variables**


| Variable                                                                      | Purpose                                                                                                                                                                        |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `RAILS_ENV`                                                                   | `staging`                                                                                                                                                                      |
| `RAILS_MASTER_KEY`                                                            | Decrypts credentials (use staging-specific credentials if you run `bin/rails credentials:edit --environment staging`)                                                          |
| `SECRET_KEY_BASE`                                                             | Hatchbox often sets this; required for sessions                                                                                                                                |
| `DATABASE_URL`                                                                | MySQL URL from Hatchbox / DigitalOcean (e.g. `mysql2://user:pass@host:3306/dbname`) — **or** omit and set `STAGING_DATABASE_`* in `[config/database.yml](config/database.yml)` |
| `STAGING_MAILER_HOST`                                                         | Public hostname for mailer URLs (e.g. `staging.example.edu`)                                                                                                                   |
| `STAGING_MAILER_PROTOCOL`                                                     | Usually `https`                                                                                                                                                                |
| `RAILS_ALLOWED_HOSTS`                                                         | Extra comma-separated hostnames for `ActionDispatch::HostAuthorization` (the public hostname is built in; `STAGING_ALLOWED_HOSTS` still works as a legacy alias)              |
| `LETTER_OPENER_WEB_HTTP_BASIC_USER` / `LETTER_OPENER_WEB_HTTP_BASIC_PASSWORD` | Optional HTTP basic auth for `/letter_opener`                                                                                                                                  |
| `RAILS_SERVE_STATIC_FILES`                                                    | Set if the app serves static files without nginx in front                                                                                                                      |
| `STAGING_FORCE_SSL`                                                           | Defaults to `true` (HTTPS, secure cookies, `assume_ssl`); set `false` only for a plain-HTTP staging box                                                                        |
| `RAILS_LOG_TO_STDOUT`                                                         | Set so Hatchbox collects the logs                                                                                                                                              |


---

## Project Structure


| Path                        | Purpose                                                                                 |
| --------------------------- | --------------------------------------------------------------------------------------- |
| `app/`                      | Models, controllers, views, mailers, helpers; the admin lives in `app/{controllers,views,helpers,filters,lib,queries}/admin/` |
| `lib/allowed_hosts.rb`      | Host allow-list for production/staging (`RAILS_ALLOWED_HOSTS`)                          |
| `lib/middleware/`           | `MaintenanceMode` and the staging `LetterOpenerWebBasicAuth` Rack middleware             |
| `app/javascript/`           | Import-map entry point (`application.js`) and Stimulus controllers                      |
| `app/assets/tailwind/`      | Tailwind 4 CSS-first config and app styles, built to `app/assets/builds/tailwind.css`   |
| `config/importmap.rb`       | JavaScript import map pins; `bin/importmap pin <pkg>` vendors into `vendor/javascript/` |
| `config/`                   | Application, routes, environments, initializers, deploy                                 |
| `Procfile` / `Procfile.dev` | Puma on `$PORT` for PaaS; local Rails server + Tailwind watcher (`bin/dev`)             |
| `config/puma.default.rb`    | Portable Puma (Hatchbox / DO); production Capistrano still uses linked `config/puma.rb` |
| `db/`                       | Schema, migrations, seeds                                                               |
| `config/deploy.rb`          | Capistrano (production): puma, maintenance, rubygems and debug tasks                    |
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