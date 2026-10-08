# frozen_string_literal: true

# The production and staging environment files are not loaded under RAILS_ENV=test, so (like
# session_config_spec.rb) this pins their wiring textually; the behaviour of the resulting
# middleware is covered by spec/lib/allowed_hosts_spec.rb.
require "rails_helper"

RSpec.describe "Host authorization and SSL configuration" do
  def environment_file(name)
    File.read(Rails.root.join("config", "environments", "#{name}.rb"))
  end

  describe "production.rb" do
    subject(:content) { environment_file(:production) }

    it "allow-lists the public hostname through AllowedHosts" do
      expect(content).to include('AllowedHosts.configure(config, "mmss-registration.math.lsa.umich.edu")')
      expect(content).not_to match(/^\s*config\.hosts\s*=/)
    end

    it "assumes SSL behind the proxy and keeps forcing it" do
      expect(content).to match(/^\s*config\.assume_ssl = true$/)
      expect(content).to match(/^\s*config\.force_ssl = true$/)
    end
  end

  describe "staging.rb" do
    subject(:content) { environment_file(:staging) }

    it "allow-lists the staging hostname and still reads the legacy STAGING_ALLOWED_HOSTS variable" do
      expect(content).to include('AllowedHosts.configure(config, "mmss-registration-staging.lsa.umich.edu"')
      expect(content).to include('env_keys: [AllowedHosts::ENV_KEY, "STAGING_ALLOWED_HOSTS"]')
    end

    it "assumes SSL whenever staging forces it" do
      expect(content).to match(/^\s*config\.assume_ssl = staging_force_ssl$/)
    end
  end
end
