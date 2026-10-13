require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../lib/middleware/maintenance_mode"

module Mmss
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    config.time_zone = "Eastern Time (US & Canada)"

    # Maintenance page driven by tmp/maintenance.yml (cap maintenance:start/stop).
    config.middleware.use MaintenanceMode

    # Attachments are documents (transcripts, tax forms, letters); no image variants are
    # generated, so skip the vips/image_processing requirement of the 7.0 defaults.
    config.active_storage.variant_processor = :disabled
  end
end
