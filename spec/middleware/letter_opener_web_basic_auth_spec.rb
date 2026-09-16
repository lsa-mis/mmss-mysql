# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/middleware/letter_opener_web_basic_auth')

RSpec.describe LetterOpenerWebBasicAuth do
  subject(:middleware) { described_class.new(app) }

  let(:app) { ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }

  def call_with(path:, headers: {})
    env = Rack::MockRequest.env_for(path)
    headers.each { |key, value| env[key] = value }
    middleware.call(env)
  end

  def basic_auth(user, password)
    encoded = Base64.strict_encode64("#{user}:#{password}")
    { 'HTTP_AUTHORIZATION' => "Basic #{encoded}" }
  end

  around do |example|
    original_user = ENV['LETTER_OPENER_WEB_HTTP_BASIC_USER']
    original_pass = ENV['LETTER_OPENER_WEB_HTTP_BASIC_PASSWORD']
    example.run
  ensure
    if original_user.nil?
      ENV.delete('LETTER_OPENER_WEB_HTTP_BASIC_USER')
    else
      ENV['LETTER_OPENER_WEB_HTTP_BASIC_USER'] = original_user
    end
    if original_pass.nil?
      ENV.delete('LETTER_OPENER_WEB_HTTP_BASIC_PASSWORD')
    else
      ENV['LETTER_OPENER_WEB_HTTP_BASIC_PASSWORD'] = original_pass
    end
  end

  it 'passes through non letter_opener paths without checking credentials' do
    ENV['LETTER_OPENER_WEB_HTTP_BASIC_USER'] = 'preview'
    ENV['LETTER_OPENER_WEB_HTTP_BASIC_PASSWORD'] = 'secret'

    status, _headers, body = call_with(path: '/admin')

    expect(status).to eq(200)
    expect(body).to eq(['OK'])
  end

  it 'passes through letter_opener when basic auth env vars are unset' do
    ENV.delete('LETTER_OPENER_WEB_HTTP_BASIC_USER')
    ENV.delete('LETTER_OPENER_WEB_HTTP_BASIC_PASSWORD')

    expect(Rails.logger).to receive(:warn).with(/not protected by HTTP basic auth/)

    status, = call_with(path: '/letter_opener')

    expect(status).to eq(200)
  end

  it 'allows letter_opener requests with valid basic auth credentials' do
    ENV['LETTER_OPENER_WEB_HTTP_BASIC_USER'] = 'preview'
    ENV['LETTER_OPENER_WEB_HTTP_BASIC_PASSWORD'] = 'secret'

    status, _headers, body = call_with(
      path: '/letter_opener',
      headers: basic_auth('preview', 'secret')
    )

    expect(status).to eq(200)
    expect(body).to eq(['OK'])
  end

  it 'rejects letter_opener requests with missing or invalid credentials' do
    ENV['LETTER_OPENER_WEB_HTTP_BASIC_USER'] = 'preview'
    ENV['LETTER_OPENER_WEB_HTTP_BASIC_PASSWORD'] = 'secret'

    status, headers, body = call_with(path: '/letter_opener')

    expect(status).to eq(401)
    expect(headers['WWW-Authenticate']).to eq('Basic realm="Letter Opener Web"')
    expect(body).to eq(['Unauthorized'])

    status, = call_with(
      path: '/letter_opener/emails',
      headers: basic_auth('preview', 'wrong')
    )
    expect(status).to eq(401)
  end
end
