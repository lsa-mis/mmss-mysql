Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.cache_classes = true
  config.eager_load = true

  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # config.require_master_key = true

  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  config.assets.compile = false

  # Local disk only (no GCS on staging).
  config.active_storage.service = :local

  config.force_ssl = ActiveModel::Type::Boolean.new.cast(ENV.fetch("STAGING_FORCE_SSL", "true"))

  # Match production session behavior on HTTPS staging (secure cookies).
  Rails.application.config.session_store :cookie_store,
    key: "mmss_security_session",
    secure: true,
    expire_after: 4.hours

  config.log_level = :info
  config.log_tags = [:request_id]

  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method = :letter_opener_web
  staging_host = ENV.fetch("STAGING_MAILER_HOST", "staging.example.edu")
  staging_protocol = ENV.fetch("STAGING_MAILER_PROTOCOL", "https")
  config.action_mailer.default_url_options = {host: staging_host, protocol: staging_protocol}

  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

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
