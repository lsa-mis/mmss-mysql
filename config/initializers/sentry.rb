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

  # Structured logging (sentry-ruby 5.24+); view in Sentry Logs and link to errors/traces
  config.enable_logs = true

  # Logging configuration
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Add user context data (PII)
  config.send_default_pii = true

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
