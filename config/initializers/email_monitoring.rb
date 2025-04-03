# Email monitoring configuration
Rails.application.config.to_prepare do
  # Subscribe to email delivery events
  ActiveSupport::Notifications.subscribe('deliver.action_mailer') do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)

    # Log successful email deliveries
    Rails.logger.info("Email delivered successfully to #{event.payload[:to]}")

    # You can add additional monitoring here, such as:
    # - Metrics collection (e.g., Prometheus)
    # - Analytics tracking
    # - Custom monitoring service
  end

  # Subscribe to email delivery errors
  ActiveSupport::Notifications.subscribe('error.action_mailer') do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)

    # Log email delivery errors
    Rails.logger.error("Email delivery error: #{event.payload[:error]}")

    # You can add additional error monitoring here, such as:
    # - Error tracking service (e.g., Sentry)
    # - Alert system
    # - Custom error monitoring service
  end
end
