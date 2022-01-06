# config valid for current version and patch releases of Capistrano
lock "~> 3.16.0"

# set ruby version, '3.1.0'
set :ruby_version, '/snap/bin/ruby'

server 'lsa-math-mmss-app.miserver.it.umich.edu', roles: %w{app db web}, primary: true

set :application, "mmss-mysql"
set :repo_url, "git@github.com:lsa-mis/mmss-mysql.git"
set :user, "deployer"
set :puma_threads,    [4, 16]
set :puma_workers,    0
set :branch, "main"

# Don't change these unless you know what you're doing
set :pty,             true
set :stage,           :production
set :deploy_via,      :remote_cache     
set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :shared_path,     "#{fetch(:deploy_to)}/shared"
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
# Avoid permissions issues with using /tmp
set :tmp_dir, '/home/deployer/tmp'

# Default value for keep_releases is 5
set :keep_releases, 3

# Default value for :linked_files and linked_dirs is []
set :linked_files, %w{config/puma.rb config/nginx.conf config/master.key config/puma.service config/lsa-was-base-c096c776ead3.json mysql/InCommon.CA.crt}
set :linked_dirs,  %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs, fetch(:linked_dirs, []).push('public/packs', 'node_modules')

namespace :puma do
  desc 'Stop the PUMA service'
  task :stop do
    on roles(:app) do
      execute "cd #{fetch(:deploy_to)}/current; /snap/bin/bundle exec pumactl -P ~/apps/#{fetch(:application)}/current/tmp/pids/puma.pid stop"
    end
  end

  desc 'Restart the PUMA service'
  task :restart do
    on roles(:app) do
      execute "cd #{fetch(:deploy_to)}/current; /snap/bin/bundle exec pumactl -P ~/apps/#{fetch(:application)}/current/tmp/pids/puma.pid phased-restart"
    end
  end

  desc 'Start the PUMA service'
  task :start do
    on roles(:app) do
      puts "You must intially start the puma service using sudo on the server"
    end
  end
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/main`
        puts "WARNING: HEAD is not the same as origin/main"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc 'Upload to shared/config'
  task :upload do
    on roles (:app) do
     upload! "config/master.key",  "#{shared_path}/config/master.key"
     upload! "config/puma_prod.rb",  "#{shared_path}/config/puma.rb"
     upload! "config/nginx_prod.conf",  "#{shared_path}/config/nginx.conf"
     upload! "config/puma_prod.service",  "#{fetch(:shared_path)}/config/puma.service"
     upload! "config/lsa-was-base-c096c776ead3.json",  "#{shared_path}/config/lsa-was-base-c096c776ead3.json"
     upload! "config/InCommon.CA.crt",  "#{shared_path}/mysql/InCommon.CA.crt"
    end
  end

  desc "reload the database with seed data"
  task :seed do
    puts "Seeding db with seed file located at db/seeds.rb"
    run "cd #{current_path}; bin/rails db:seed RAILS_ENV=production"
  end

  before :starting,     :check_revision
  after  :finishing,    'puma:restart'
end

namespace :maintenance do
  desc "Maintenance start (edit config/maintenance_template.yml to provide parameters)"
  task :start do
    on roles(:web) do
      upload! "config/maintenance_template.yml", "#{current_path}/tmp/maintenance.yml"
    end
  end

  desc "Maintenance stop"
  task :stop do
    on roles(:web) do
      execute "rm #{current_path}/tmp/maintenance.yml"
    end
  end
end
