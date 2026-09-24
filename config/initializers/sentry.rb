# frozen_string_literal: true

Sentry.init do |config|
  # Use credentials in production/staging when available, otherwise fall back to ENV
  config.dsn = begin
    Rails.application.credentials.dig(:sentry, :dsn)
  rescue Errno::ENOENT, Errno::EACCES, Errno::EPERM, IOError, ActiveSupport::MessageEncryptor::InvalidMessage, ArgumentError
    ENV['SENTRY_DSN']
  end

  # Only enable in production and staging environments
  config.enabled_environments = %w[production staging]

  # Release for deploy tracking and suspect commits (set by Capistrano REVISION file or ENV)
  config.release = ENV["SENTRY_RELEASE"].presence ||
    (File.read(Rails.root.join("REVISION")).strip if Rails.root.join("REVISION").exist?)

  # Sentry Logs and Metrics are on by default since sentry-ruby 7.0; sentry-rails also forwards
  # Rails structured logs. Opt out with `config.rails.structured_logging.enabled = false`.

  # Logging configuration
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Data collection (replaces send_default_pii = true in sentry-ruby 7.0): keep user context,
  # query strings, request bodies, SQL and job data; cookies (session tokens) are not sent.
  config.data_collection.user_info = true
  config.data_collection.url_query_params = true
  config.data_collection.http_bodies = nil # all body types
  config.data_collection.database_query_data = true
  config.data_collection.queues = true
  config.data_collection.cookies = false

  # Performance monitoring: traces_sampler is the single source of truth (overrides traces_sample_rate)
  config.traces_sampler = lambda do |context|
    name = context[:transaction_context][:name].to_s
    if name.include?("health_check")
      0.0
    else
      Rails.env.production? ? 0.1 : 1.0
    end
  end

  # Profile sampling - adjust based on your needs
  config.profiles_sample_rate = Rails.env.production? ? 0.1 : 1.0

  # Add additional context to errors
  config.before_send = lambda do |event, _hint|
    # You can add custom data here
    if defined?(Current) && Current.user
      event.user = {
        id: Current.user.id,
        email: Current.user.email
      }
    end
    event
  end

  # Configure backtrace cleanup
  config.backtrace_cleanup_callback = lambda do |backtrace|
    Rails.backtrace_cleaner.clean(backtrace)
  end
end
