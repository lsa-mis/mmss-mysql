set :rails_env, 'production'
append :default_env, 'NODE_OPTIONS' => '--openssl-legacy-provider'