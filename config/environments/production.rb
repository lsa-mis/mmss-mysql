require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Disable serving static files from the `/public` folder by default since
  # NGINX already handles this. Hosts that need Rails to serve them (e.g. Hatchbox)
  # set RAILS_SERVE_STATIC_FILES.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  # (CSS compression is disabled app-wide in config/application.rb; the Tailwind build is pre-minified.)
  config.assets.compile = false

  # Store uploaded files on Google Cloud Storage (see config/storage.yml for options).
  config.active_storage.service = :google

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # NGINX forwards X-Forwarded-Proto, so `assume_ssl` is not needed.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Ensure the session cookies are also set to secure in production
  # Extended timeout (4 hours) to accommodate long forms like enrollment applications
  # This prevents CSRF token expiration while users fill out lengthy forms
  config.session_store :cookie_store,
    key: "mmss_security_session",
    secure: true,
    expire_after: 4.hours

  # Prepend all log lines with the request id. Logs go to log/production.log unless
  # RAILS_LOG_TO_STDOUT is set (e.g. on Hatchbox), in which case they go to STDOUT.
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger($stdout) if ENV["RAILS_LOG_TO_STDOUT"].present?

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :mem_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :resque

  # Deliver mail through SendGrid; raise so delivery problems surface in Sentry.
  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = { host: "mmss-registration.math.lsa.umich.edu", protocol: "https" }
  config.action_mailer.smtp_settings = {
    address: "smtp.sendgrid.net",
    port: 587,
    authentication: :plain,
    user_name: "apikey",
    password: Rails.application.credentials.SENDGRID_API_KEY,
    domain: "math.lsa.umich.edu",
    enable_starttls_auto: true
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [:id]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
