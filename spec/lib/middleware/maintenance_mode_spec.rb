# frozen_string_literal: true

require 'rails_helper'
require 'rack/mock'
require 'tmpdir'

RSpec.describe MaintenanceMode do
  let(:downstream) { ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['app response']] } }
  let(:root) { Pathname(Dir.mktmpdir) }
  let(:maintenance_file) { root.join('tmp', 'maintenance.yml') }
  let(:app) { described_class.new(downstream, root: root) }

  def request(path = '/', env = {})
    Rack::MockRequest.new(app).get(path, env)
  end

  def enable_maintenance(settings)
    maintenance_file.dirname.mkpath
    maintenance_file.write(settings.to_yaml)
  end

  before do
    root.join('public').mkpath
    root.join('public', 'maintenance.html').write("<html><body><div>{{ reason }}</div></body></html>\n")
  end

  after { FileUtils.remove_entry(root) }

  it 'passes requests through when tmp/maintenance.yml does not exist' do
    response = request

    expect(response.status).to eq(200)
    expect(response.body).to eq('app response')
  end

  context 'when tmp/maintenance.yml exists' do
    before do
      enable_maintenance(
        'reason' => "Down for maintenance. <small>(code 1)</small>\nBack soon.",
        'allowed_paths' => nil,
        'allowed_ips' => ['35.7.0.0/18'],
        'response_code' => 503,
        'retry_after' => 3600
      )
    end

    it 'renders public/maintenance.html with the reason and the configured status and Retry-After' do
      response = request

      # Goes through the real Rack::Response of the installed Rack (2.2.x today, 3.x after Rails 8.1);
      # a missing Response API would surface here rather than on the first production request.
      expect(Rack::Response.method_defined?(:set_header)).to be(true), "Rack #{Rack.release} lacks Response#set_header"
      expect(response.status).to eq(503)
      expect(response.headers['Retry-After']).to eq('3600')
      expect(response.headers['Content-Type']).to eq('text/html')
      expect(response.headers['Content-Length']).to eq(response.body.bytesize.to_s)
      expect(response.body).to include('<p>Down for maintenance. <small>(code 1)</small></p>')
      expect(response.body).to include('<p>Back soon.</p>')
      expect(response.body).not_to include('{{ reason }}')
    end

    it 'lets requests from allowed IP ranges through' do
      response = request('/', 'REMOTE_ADDR' => '35.7.10.20')

      expect(response.status).to eq(200)
      expect(response.body).to eq('app response')
    end

    it 'blocks requests from other IPs' do
      expect(request('/', 'REMOTE_ADDR' => '203.0.113.5').status).to eq(503)
    end

    describe 'X-Forwarded-For handling' do
      it 'ignores a forged X-Forwarded-For on a direct (non-proxied) connection' do
        response = request('/', 'REMOTE_ADDR' => '203.0.113.5', 'HTTP_X_FORWARDED_FOR' => '35.7.0.1')

        expect(response.status).to eq(503)
      end

      it 'ignores a forged X-Forwarded-For behind nginx ($proxy_add_x_forwarded_for appends the real client)' do
        response = request('/', 'REMOTE_ADDR' => '127.0.0.1',
                                'HTTP_X_FORWARDED_FOR' => '35.7.0.1, 203.0.113.5')

        expect(response.status).to eq(503)
      end

      it 'ignores forged trusted-range hops appended by the client' do
        response = request('/', 'REMOTE_ADDR' => '127.0.0.1',
                                'HTTP_X_FORWARDED_FOR' => '35.7.0.1, 10.0.0.9, 203.0.113.5')

        expect(response.status).to eq(503)
      end

      it 'allows a genuine allowed client forwarded by the local proxy' do
        response = request('/', 'REMOTE_ADDR' => '127.0.0.1', 'HTTP_X_FORWARDED_FOR' => '35.7.1.1')

        expect(response.status).to eq(200)
      end
    end

    it 'falls back to a built-in page when public/maintenance.html is missing' do
      root.join('public', 'maintenance.html').delete
      response = request

      expect(response.status).to eq(503)
      expect(response.body).to include('<p>Down for maintenance. <small>(code 1)</small></p>')
    end
  end

  it 'passes the request through when tmp/maintenance.yml disappears mid-request (maintenance:stop race)' do
    enable_maintenance('reason' => 'Down')
    # Simulate `maintenance:stop` deleting the marker after the middleware decided to read it.
    allow_any_instance_of(Pathname).to receive(:read).and_wrap_original do |original, *args|
      original.receiver.delete if original.receiver.basename.to_s == 'maintenance.yml'
      original.call(*args)
    end

    response = request

    expect(response.status).to eq(200)
    expect(response.body).to eq('app response')
  end

  it 'applies turnout-compatible defaults when the file is empty' do
    enable_maintenance({})
    maintenance_file.write('')

    response = request

    expect(response.status).to eq(503)
    expect(response.headers['Retry-After']).to eq('7200')
    expect(response.body).to include('<p>The site is temporarily down for maintenance.</p>')
  end

  it 'lets requests matching allowed_paths through (regexp match, comma-separated string accepted)' do
    enable_maintenance('allowed_paths' => '^/admin, ^/healthz$')

    expect(request('/admin/dashboard').status).to eq(200)
    expect(request('/healthz').status).to eq(200)
    expect(request('/enrollments').status).to eq(503)
  end
end
