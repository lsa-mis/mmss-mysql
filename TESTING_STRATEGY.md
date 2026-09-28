# Testing Strategy

How the MMSS suite is organised, how to run it, and the conventions that keep it green.

## What runs where

| Layer | Location | Notes |
| --- | --- | --- |
| Model specs | `spec/models/` | Associations/validations via shoulda-matchers, scopes, callbacks (`Enrollment#withdraw!`, `Payment` status, `FinancialAid` award emails), factory traits |
| Request specs | `spec/requests/` | The bulk of the suite. `spec/requests/admin/*` covers every `Admin::` resource (anonymous redirect, index + scopes + filters + sort + CSV, show, new/create, edit/update + 422, destroy, batch actions). `spec/requests/applicant_scoping_spec.rb` pins that applicant-facing controllers scope through `current_user` and that admin sessions are redirected to the applicant sign-in |
| Library / query specs | `spec/lib/`, `spec/queries/` | `Admin::Filter`, `Admin::CsvExport` (formula guard), `Admin::MoneyInput`, `AllowedHosts`, the maintenance / letter-opener middleware, the 18 `Admin::Reports::*` SQL reports (every statement executes, headers pinned in `AdminReportFixtures::EXPECTED_HEADERS`) |
| Controller / helper / view / mailer specs | `spec/controllers/`, `spec/helpers/`, `spec/views/`, `spec/mailers/` | Legacy-style controller specs are kept only where a request spec would not add anything |
| Config specs | `spec/config/` | Textual pins of `config/environments/production.rb` and `staging.rb` (session store, host authorization, `assume_ssl`, Sentry) because those files are never loaded under `RAILS_ENV=test` |
| System specs | `spec/system/` | Capybara + Selenium, headless Chrome (`SHOW_BROWSER=1` for a visible browser); Turbo Drive flows: registration, application status, feedback, session timeout |

Support code: `spec/support/factory_bot.rb`, `spec/support/capybara.rb`, `spec/support/features/session_helpers.rb`
(sign-in helpers for system specs), `spec/support/helpers/` (`create_complete_enrollment`, `create_camp_setup`,
`setup_basic_test_data`, report fixtures), `spec/support/shared_examples/model_validations.rb`.

Data: FactoryBot factories for every model (`spec/factories/`), Faker for names/emails. DatabaseCleaner runs
transactions per example and truncation for system specs; Warden is reset after every example.

## Running

```bash
RAILS_ENV=test bin/rails db:create db:schema:load   # once
bin/rails tailwindcss:build                          # request and system specs render the layouts
bundle exec rspec                                    # everything, including system specs
bundle exec rspec --exclude-pattern "spec/system/**/*"   # what CI runs
bundle exec rspec spec/requests/admin/courses_spec.rb:42  # one example
```

SimpleCov writes `coverage/index.html` (grouped by models, controllers, helpers, mailers, lib); line coverage is
~92% with the full suite.

## CI

`.github/workflows/ci.yml` runs on every pull request and on pushes to `staging`/`main`: Ruby from
`.ruby-version` (`ruby/setup-ruby` with the bundle cached), a MySQL 8 service container, `tailwindcss:build`,
`db:schema:load`, then RSpec without the system specs. The coverage report is uploaded as an artifact. Run the
system specs locally before merging a change to a Turbo/Stimulus flow.

## Conventions

- **Request specs, not controller specs**, for new coverage. Sign in with Devise's `sign_in` (`create(:admin)`
  or `create(:user, :with_applicant_detail)`); note that `sign_in` only prepares the next request, so make one
  ordinary request before asserting on a 404 (the exceptions app does not commit the session cookie).
- **HTML-escaped text**: Faker names contain apostrophes (`O'Neil`), which the views escape to `&#39;`. Assert
  through `CGI.unescapeHTML(response.body)` (or the `include_unescaped` matcher in `spec/support/`), never
  `include(name)` on the raw body.
- **Camp years**: the `camp_configuration` factory allocates years above the current year, so it never collides
  with the `:current_year` / `:next_year` traits whichever year the suite runs in. Anything that needs "the
  active camp" should `create(:camp_configuration, :current_year)` (or `create_camp_setup`) rather than assume
  a hard-coded year.
- **Pagination**: give at least one admin index spec more than 30 rows (or `limit: 1, page: 2`) so the
  pagination partial is actually rendered.
- **Filter selects that list applicants** make `not_to include('Anderson')` unreliable; assert on `id="<dom_id>"`
  rows instead.
- **Security regressions** get a spec next to the fix: applicant scoping (`applicant_scoping_spec.rb`), CSV
  formula injection (`spec/lib/admin/csv_export_spec.rb` + one export per resource with a `=HYPERLINK(` cell),
  URL options smuggled into query strings (`spec/requests/admin/applications_spec.rb`), host authorization
  (`spec/lib/allowed_hosts_spec.rb`).
- **Money**: assert formatted strings (`$1,234.50`, `$-25.00`) rather than `Money` objects; `Admin::MoneyInput`
  is the only parser for admin money fields and has its own spec.
- Keep factories realistic but minimal; prefer traits over new factories; never depend on `db/seeds.rb` in
  specs (`load_test_seeds_if_needed` exists only for the system specs that walk the seeded site).
