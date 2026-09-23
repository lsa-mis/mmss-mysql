# frozen_string_literal: true

require 'ipaddr'
require 'yaml'
require 'rack'

# Serves a maintenance page while tmp/maintenance.yml exists.
#
# `cap production maintenance:start` uploads config/maintenance_template.yml to
# tmp/maintenance.yml on the server and `maintenance:stop` deletes it (see
# config/deploy.rb). This middleware replaces the unmaintained `turnout` gem
# (Rack 2 only) and keeps its contract: same file location, same YAML keys
# (reason, allowed_paths, allowed_ips, response_code, retry_after) and the same
# `{{ reason }}` placeholder in public/maintenance.html.
class MaintenanceMode
  DEFAULTS = {
    'reason' => "The site is temporarily down for maintenance.\nPlease check back soon.",
    'allowed_paths' => [],
    'allowed_ips' => [],
    'response_code' => 503,
    'retry_after' => 7200
  }.freeze

  FALLBACK_PAGE = <<~HTML
    <!DOCTYPE html>
    <html>
      <head><meta charset="UTF-8"><title>Down for maintenance</title></head>
      <body>{{ reason }}</body>
    </html>
  HTML

  def initialize(app, root: Rails.root)
    @app = app
    @maintenance_file = Pathname(root).join('tmp', 'maintenance.yml')
    @page_file = Pathname(root).join('public', 'maintenance.html')
  end

  def call(env)
    return @app.call(env) unless @maintenance_file.exist?

    settings = load_settings
    return @app.call(env) if allowed?(Rack::Request.new(env), settings)

    maintenance_response(settings)
  end

  private

  def load_settings
    yaml = YAML.safe_load(@maintenance_file.read) || {}
    settings = DEFAULTS.merge(yaml.transform_keys(&:to_s).compact)
    settings['allowed_paths'] = to_list(settings['allowed_paths'])
    settings['allowed_ips'] = to_list(settings['allowed_ips'])
    settings
  end

  # Accepts YAML arrays or comma-separated strings, like turnout did.
  def to_list(value)
    value = value.split(',') if value.is_a?(String)
    Array(value).map { |item| item.to_s.strip }.reject(&:empty?)
  end

  def allowed?(request, settings)
    path_allowed?(request.path, settings['allowed_paths']) ||
      ip_allowed?(request.ip, settings['allowed_ips'])
  end

  def path_allowed?(path, allowed_paths)
    allowed_paths.any? { |pattern| path.match?(Regexp.new(pattern)) }
  end

  def ip_allowed?(remote_ip, allowed_ips)
    ip = IPAddr.new(remote_ip.to_s)
    allowed_ips.any? { |allowed| IPAddr.new(allowed).include?(ip) }
  rescue ArgumentError # includes IPAddr::Error
    false
  end

  def maintenance_response(settings)
    body = page_content(settings['reason'])
    response = Rack::Response.new(body, settings['response_code'].to_i)
    response.set_header('Content-Type', 'text/html')
    response.set_header('Content-Length', body.bytesize.to_s)
    response.set_header('Retry-After', settings['retry_after'].to_s)
    response.finish
  end

  def page_content(reason)
    template = @page_file.exist? ? @page_file.read : FALLBACK_PAGE
    template.gsub(/{{\s?reason\s?}}/, html_reason(reason))
  end

  def html_reason(reason)
    reason.to_s.split("\n").map { |line| "<p>#{line}</p>" }.join("\n")
  end
end
