# frozen_string_literal: true

module EmailErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |exception|
      Rails.logger.error("Email delivery failed: #{exception.message}")
      Rails.logger.error(exception.backtrace.join("\n"))

      # You can add additional error reporting here, such as:
      # - Sentry notification
      # - Email to admin
      # - Custom error tracking service

      # Re-raise the exception if we want to maintain the current behavior
      # of raising delivery errors
      raise exception if Rails.application.config.action_mailer.raise_delivery_errors
    end
  end
end
