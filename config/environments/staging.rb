Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.enable_reloading = false
  config.eager_load = true

  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # config.require_master_key = true

  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.public_file_server.headers = {"cache-control" => "public, max-age=#{1.year.to_i}"}

  config.assets.compile = false

  # Local disk only (no GCS on staging).
  config.active_storage.service = :local

  # STAGING_FORCE_SSL=false runs staging over plain HTTP; the session cookie must then not be
  # marked Secure, or browsers would never send it back and every request would look logged out.
  staging_force_ssl = ActiveModel::Type::Boolean.new.cast(ENV.fetch("STAGING_FORCE_SSL", "true"))
  config.force_ssl = staging_force_ssl
  config.ssl_options = {redirect: {exclude: ->(request) { request.path == "/up" }}}

  # Match production session behavior on HTTPS staging (secure cookies).
  config.session_store :cookie_store,
    key: "mmss_security_session",
    secure: staging_force_ssl,
    expire_after: 4.hours

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [:request_id]
  config.silence_healthcheck_path = "/up"
  config.active_record.attributes_for_inspect = [:id]

  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method = :letter_opener_web
  staging_host = ENV.fetch("STAGING_MAILER_HOST", "staging.example.edu")
  staging_protocol = ENV.fetch("STAGING_MAILER_PROTOCOL", "https")
  config.action_mailer.default_url_options = {host: staging_host, protocol: staging_protocol}

  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false

  # Hatchbox collects STDOUT; set RAILS_LOG_TO_STDOUT there.
  config.logger = ActiveSupport::TaggedLogging.logger($stdout) if ENV["RAILS_LOG_TO_STDOUT"].present?

  config.active_record.dump_schema_after_migration = false

  # HostAuthorization behind reverse proxies: set STAGING_ALLOWED_HOSTS=comma,separated,hosts
  if (hosts = ENV["STAGING_ALLOWED_HOSTS"].presence)
    hosts.split(",").map(&:strip).reject(&:empty?).each do |host|
      config.hosts << host
    end
  end

  require Rails.root.join("lib/middleware/letter_opener_web_basic_auth")
  config.middleware.use LetterOpenerWebBasicAuth
end
