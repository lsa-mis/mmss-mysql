# frozen_string_literal: true

# Portable Puma config for Hatchbox, DigitalOcean, and other hosts that bind to $PORT
# (Capistrano production continues to use the server-linked config/puma.rb from puma_prod.rb.)

max_threads = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
threads max_threads, max_threads

port ENV.fetch("PORT", 3000)

environment ENV.fetch("RAILS_ENV", "development")

plugin :tmp_restart
