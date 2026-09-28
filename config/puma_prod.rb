#!/usr/bin/env puma

# Production Puma config for the Capistrano-deployed UM host. `cap production deploy:upload`
# copies this file to shared/config/puma.rb, which is linked into each release.

directory "/home/deployer/apps/mmss-mysql/current"
rackup "/home/deployer/apps/mmss-mysql/current/config.ru"
environment "production"

tag "mmss-mysql-production"

pidfile "/home/deployer/apps/mmss-mysql/shared/tmp/pids/puma.pid"
state_path "/home/deployer/apps/mmss-mysql/shared/tmp/pids/puma.state"
stdout_redirect "/home/deployer/apps/mmss-mysql/current/log/puma.error.log", "/home/deployer/apps/mmss-mysql/current/log/puma.access.log", true

threads 4, 16

bind "unix:///home/deployer/apps/mmss-mysql/shared/tmp/sockets/mmss-mysql-puma.sock"

workers 2

preload_app!

# systemd integration: Puma >= 6 enables its built-in systemd plugin automatically when it is
# started by a `Type=notify` unit (NOTIFY_SOCKET is set), so no `sd_notify` gem or explicit
# `plugin :systemd` is needed. See config/puma_prod.service.

# Active Record reconnects after fork on its own (Rails >= 5.2), so no before_fork /
# before_worker_boot connection handling is required.

before_restart do
  puts "Refreshing Gemfile"
  ENV["BUNDLE_GEMFILE"] = "/home/deployer/apps/mmss-mysql/current/Gemfile"
end
