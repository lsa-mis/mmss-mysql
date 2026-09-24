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

  # sentry-ruby 7.0 enables Sentry Logs by default and sentry-rails would forward Rails
  # controller/Active Record events to it. That is a capture surface the app never had, so it
  # stays off; errors, breadcrumbs and traces are unaffected.
  config.rails.structured_logging.enabled = false

  # Logging configuration
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Data collection (replaces send_default_pii in sentry-ruby 7.0). Configured to be no
  # broader than what sentry-ruby 6 sent, minus request payloads:
  # - no request/response bodies, query strings or cookies: they carry passwords, Devise reset
  #   tokens, Nelnet callback signatures and applicant/financial fields, and Sentry's own
  #   scrubbing is shallow (nested keys such as user[password] would pass through);
  # - no SQL bind values (db.query.parameter.*) and no Active Job arguments/context;
  # - user id/email/IP context and the Rails breadcrumbs stay on, as before.
  # Whatever request data remains (headers) is additionally filtered with the Rails parameter
  # filter terms. Asserted by spec/config/sentry_config_spec.rb.
  config.data_collection.user_info = true
  config.data_collection.url_query_params = false
  config.data_collection.http_bodies = []
  config.data_collection.cookies = false
  config.data_collection.database_query_data = false
  config.data_collection.queues = false
  config.data_collection.graphql.document = false
  config.data_collection.graphql.variables = false
  rails_filter_terms = Rails.application.config.filter_parameters.select { |f| f.is_a?(String) || f.is_a?(Symbol) || f.is_a?(Regexp) }
  config.data_collection.http_headers.request.terms = (Sentry::DataCollection::PII_HEADER_SNIPPETS + rails_filter_terms).uniq
  config.data_collection.http_headers.response.terms = (Sentry::DataCollection::PII_HEADER_SNIPPETS + rails_filter_terms).uniq

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
