set :stage, :production
set :rails_env, "production"

server "mathmmssapp2.miserver.it.umich.edu", roles: %w[app db web], primary: true
