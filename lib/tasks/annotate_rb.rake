# This rake task was added by annotate_rb gem.

# Can set `ANNOTATERB_SKIP_ON_DB_TASKS` to be anything to skip this
if Rails.env.development? && ENV["ANNOTATERB_SKIP_ON_DB_TASKS"].nil?
  require "annotate_rb"

  # Can modify the config path here if needed - by default, it's .annotaterb.yml in the root of the project
  # AnnotateRb::ConfigFinder.config_path = ""
  AnnotateRb::Core.load_rake_tasks

  # .annotaterb.yml sets skip_on_db_migrate: true, so the gem's db:migrate hook is inert and
  # annotations only change when this task is run explicitly (same as `bundle exec annotaterb models`).
  desc "Refresh the schema annotations in app/models, spec/factories and spec/models"
  task annotate_models: :environment do
    AnnotateRb::Runner.run(["models"])
  end
end
