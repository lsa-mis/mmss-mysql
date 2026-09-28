# frozen_string_literal: true

# Host allow-list for ActionDispatch::HostAuthorization on the deployed environments.
#
# Each environment has one canonical public hostname (set in config/environments/*.rb). The
# RAILS_ALLOWED_HOSTS environment variable (comma-separated) adds more without a deploy — the UM
# cluster's internal node names, a Hatchbox preview hostname, an IP used by a load balancer.
# Entries are passed to Rails untouched, so its own syntax works: a leading dot allows every
# subdomain (`.lsa.umich.edu`).
#
# `/up` is exempt from the check so health checks, which usually address the node by IP or by an
# internal name, are never answered with a 403. Everything else that arrives with a foreign Host
# (or X-Forwarded-Host) header is blocked, which is what defeats DNS rebinding and cache poisoning
# through a spoofed Host.
module AllowedHosts
  ENV_KEY = "RAILS_ALLOWED_HOSTS"
  HEALTH_CHECK_PATH = "/up"

  # Applies the allow-list to a Rails configuration object.
  #
  #   AllowedHosts.configure(config, "mmss-registration.math.lsa.umich.edu")
  #
  # `env_keys:` lists the environment variables read for extra hosts (RAILS_ALLOWED_HOSTS plus
  # any legacy alias); `env:` is injectable for specs.
  def self.configure(config, *default_hosts, env_keys: [ENV_KEY], env: ENV)
    config.hosts = list(*default_hosts, env_keys: env_keys, env: env)
    config.host_authorization = authorization_options
    config
  end

  # The final host list: defaults first, then every non-blank, comma-separated entry from the
  # given environment variables, de-duplicated.
  def self.list(*default_hosts, env_keys: [ENV_KEY], env: ENV)
    extra = env_keys.flat_map { |key| env.fetch(key, "").split(",") }
    (default_hosts.flatten + extra).map(&:strip).reject(&:empty?).uniq
  end

  def self.authorization_options
    {exclude: ->(request) { request.path == HEALTH_CHECK_PATH }}
  end
end
