source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '4.0.6'

gem 'bootsnap', '~> 1.18', require: false
gem 'country_select', '~> 11.0'
gem 'devise', '~> 5.0'
# 1.3 drops SortedSet, which Ruby 4.0 no longer autoloads (rake dump:* raised NameError on 1.2).
gem 'dump', '~> 1.3'
gem 'drb', '~> 2.2'
gem 'google-cloud-storage', '~> 1.58', require: false
gem 'money-rails', '~> 3.0'
# gem install mysql2 -v '0.5.4' -- --with-ldflags=-L/usr/local/opt/openssl/lib --with-cppflags=-I/usr/local/opt/openssl/include
# gem install mysql2 -v '0.5.6' -- --with-mysql-dir=/opt/homebrew/bin/mysql --with-mysql-lib=/opt/homebrew/Cellar/mysql/8.3.0/lib --with-mysql-include=/opt/homebrew/Cellar/mysql/8.3.0/include/mysql
gem 'mysql2', '~> 0.5.6'
gem 'ostruct', '~> 0.6'
# Pagination for the Admin:: namespace.
gem 'pagy', '~> 43.6'
gem 'puma', '~> 8.0'
gem 'rails', '~> 8.1.3'
# Rails 8 asset pipeline: digests and serves app/assets/builds (Tailwind output), app/assets/images
# and the importmap modules. No compilation step of its own, so no Node on the servers.
gem 'propshaft', '~> 1.3'
gem 'skylight', '~> 7.1'
gem 'tzinfo-data', platforms: %i[windows jruby]

# Node-free front end: import maps for JS, Hotwire (Turbo Drive + Stimulus), Tailwind 4 via the standalone CLI.
gem 'importmap-rails', '~> 2.2'
gem 'stimulus-rails', '~> 1.3'
gem 'tailwindcss-rails', '~> 4.4'
gem 'turbo-rails', '~> 2.0'

gem 'base64', require: false
# Bundled gem on Ruby 3.4+; Admin::CsvExport writes the admin exports and reports.
gem 'csv'
gem 'matrix', '~> 0.4.2', require: false
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false

gem 'nokogiri', '~> 1.19'

gem 'sentry-rails', '~> 7.0'
gem 'sentry-ruby', '~> 7.0'
gem 'stackprof'

# Seeds use Faker; staging loads seeds but should not install full :test tooling (Capybara, RSpec, …).
group :development, :test, :staging do
  gem 'faker', '~> 3.8'
end

group :development, :test do
  gem 'capybara', '~> 3.40'
  gem 'factory_bot_rails', '~> 6.5'
  gem 'pry-byebug', '~> 3.12'
  gem 'pry-rails', '~> 0.3.9'
  gem 'rspec-rails', '~> 8.0'
  gem 'selenium-webdriver', '~> 4.40'
  gem 'shoulda-matchers', '~> 8.0'
  gem 'standard'
  # webdrivers gem is deprecated - Selenium 4.11+ includes Selenium Manager
  # gem 'webdrivers', '~> 5.3'
end

group :test do
  gem 'database_cleaner-active_record', '~> 2.0'
  gem 'rails-controller-testing'
  gem 'simplecov', '~> 1.3', require: false
end

group :development, :staging do
  # letter_opener_web loads rexml; not guaranteed on Ruby 3.4+ without an explicit gem
  gem 'rexml'
  gem 'letter_opener_web', '~> 3.0'
end

group :development do
  gem 'annotaterb', '~> 4.25'
  gem 'better_errors', '~> 2.10'
  gem 'capistrano', '~> 3.16', require: false
  gem 'capistrano-asdf', require: false
  gem 'capistrano-rails', '~> 1.6', '>= 1.6.1', require: false
  gem 'ed25519', '~> 1.3'
  gem 'bcrypt_pbkdf', '~> 1.1'
  gem 'listen', '~> 3.7'
  gem 'web-console', '~> 4.2'
end
