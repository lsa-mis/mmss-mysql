require_relative 'boot'

require 'logger'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative '../lib/middleware/maintenance_mode'

module Mmss
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    config.time_zone = 'Eastern Time (US & Canada)'

    # Maintenance page driven by tmp/maintenance.yml (cap maintenance:start/stop).
    config.middleware.use MaintenanceMode

    # sassc-rails would otherwise register libsass as the Sprockets CSS compressor,
    # and libsass cannot parse the modern CSS emitted by Tailwind 4 (range media
    # queries, nesting). The Tailwind build is already minified outside development.
    config.assets.css_compressor = nil

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
