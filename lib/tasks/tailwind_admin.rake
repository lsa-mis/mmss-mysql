# frozen_string_literal: true

# The admin UI ships its own Tailwind entry point (app/assets/tailwind/admin.css ->
# app/assets/builds/admin.css) so it is not subject to the applicant stylesheet's global
# element rules. tailwindcss-rails only compiles application.css, so these tasks build the
# admin bundle and hook into the gem's build task (which assets:precompile already depends on).
namespace :tailwindcss do
  admin_command = lambda do |debug: false, watch: false|
    command = [
      Tailwindcss::Ruby.executable,
      '-i', Rails.root.join('app/assets/tailwind/admin.css').to_s,
      '-o', Rails.root.join('app/assets/builds/admin.css').to_s
    ]
    command << '--minify' unless debug
    command << '-w' if watch
    command
  end

  namespace :build do
    desc 'Build the admin Tailwind CSS (app/assets/builds/admin.css)'
    task admin: :environment do |_, args|
      system(*admin_command.call(debug: args.extras.include?('debug')), exception: true)
    end
  end

  namespace :watch do
    desc 'Watch and build the admin Tailwind CSS on file changes'
    task admin: :environment do |_, args|
      system(*admin_command.call(debug: args.extras.include?('debug'), watch: true))
    end
  end
end

Rake::Task['tailwindcss:build'].enhance(['tailwindcss:build:admin'])
