# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/allowed_hosts')

RSpec.describe AllowedHosts do
  let(:production_host) { 'mmss-registration.math.lsa.umich.edu' }

  describe '.list' do
    it 'is just the default hosts when RAILS_ALLOWED_HOSTS is unset' do
      expect(described_class.list(production_host, env: {})).to eq([production_host])
    end

    it 'appends the comma-separated RAILS_ALLOWED_HOSTS entries, trimmed and without blanks' do
      env = { 'RAILS_ALLOWED_HOSTS' => ' node1.internal.umich.edu, 10.0.0.12 ,,.lsa.umich.edu ' }

      expect(described_class.list(production_host, env: env))
        .to eq([production_host, 'node1.internal.umich.edu', '10.0.0.12', '.lsa.umich.edu'])
    end

    it 'ignores a blank variable and de-duplicates' do
      expect(described_class.list(production_host, env: { 'RAILS_ALLOWED_HOSTS' => '' })).to eq([production_host])
      expect(described_class.list(production_host, env: { 'RAILS_ALLOWED_HOSTS' => production_host }))
        .to eq([production_host])
    end

    it 'reads every listed environment variable (legacy alias support)' do
      env = { 'RAILS_ALLOWED_HOSTS' => 'a.example', 'STAGING_ALLOWED_HOSTS' => 'b.example' }

      expect(described_class.list('s.example', env_keys: %w[RAILS_ALLOWED_HOSTS STAGING_ALLOWED_HOSTS], env: env))
        .to eq(%w[s.example a.example b.example])
    end
  end

  describe '.configure' do
    let(:config) { ActiveSupport::OrderedOptions.new.tap { |c| c.hosts = [] } }

    it 'sets config.hosts and exempts the health check path' do
      described_class.configure(config, production_host, env: { 'RAILS_ALLOWED_HOSTS' => 'internal.example' })

      expect(config.hosts).to eq([production_host, 'internal.example'])
      exclude = config.host_authorization.fetch(:exclude)
      expect(exclude.call(ActionDispatch::Request.new(Rack::MockRequest.env_for('/up')))).to be(true)
      expect(exclude.call(ActionDispatch::Request.new(Rack::MockRequest.env_for('/up/')))).to be(false)
      expect(exclude.call(ActionDispatch::Request.new(Rack::MockRequest.env_for('/admin')))).to be(false)
    end
  end

  describe 'ActionDispatch::HostAuthorization built from the configuration' do
    let(:env_vars) { {} }
    let(:middleware) do
      config = ActiveSupport::OrderedOptions.new
      described_class.configure(config, production_host, env: env_vars)
      inner = ->(_env) { [200, { 'content-type' => 'text/plain' }, ['ok']] }
      ActionDispatch::HostAuthorization.new(inner, config.hosts, **config.host_authorization)
    end

    # Rack::MockRequest only fills SERVER_NAME from the URL; HostAuthorization reads the Host header.
    def request_env(host, path = '/', headers = {})
      Rack::MockRequest.env_for("http://#{host}#{path}", { 'HTTP_HOST' => host }.merge(headers))
    end

    def status_for(host, path = '/')
      middleware.call(request_env(host, path)).first
    end

    it 'serves the canonical hostname' do
      expect(status_for(production_host)).to eq(200)
      expect(status_for(production_host, '/admin/login')).to eq(200)
    end

    it 'blocks every other Host header' do
      expect(status_for('evil.example')).to eq(403)
      expect(status_for('127.0.0.1')).to eq(403)
      expect(status_for('mmss-registration-staging.lsa.umich.edu')).to eq(403)
    end

    it 'blocks a spoofed X-Forwarded-Host even when Host is allowed' do
      env = request_env(production_host, '/', 'HTTP_X_FORWARDED_HOST' => 'evil.example')

      expect(middleware.call(env).first).to eq(403)
    end

    it 'always answers /up so health checks can address the node by IP or internal name' do
      expect(status_for('10.0.0.12', '/up')).to eq(200)
      expect(status_for('evil.example', '/up')).to eq(200)
      expect(status_for('10.0.0.12', '/up?probe=1')).to eq(200)
    end

    context 'with RAILS_ALLOWED_HOSTS set' do
      let(:env_vars) { { 'RAILS_ALLOWED_HOSTS' => 'mathmmssapp2.miserver.it.umich.edu, .internal.umich.edu' } }

      it 'also serves the extra hostnames and a dotted subdomain wildcard' do
        expect(status_for('mathmmssapp2.miserver.it.umich.edu')).to eq(200)
        expect(status_for('node7.internal.umich.edu')).to eq(200)
        expect(status_for(production_host)).to eq(200)
        expect(status_for('evil.example')).to eq(403)
      end
    end
  end
end
