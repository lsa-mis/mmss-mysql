# frozen_string_literal: true

require 'rails_helper'
require 'rack/mock'

# The Sentry event payload is assembled from the Rack env through Sentry::Event#rack_env=,
# using the data_collection settings from config/initializers/sentry.rb. These specs build
# events exactly that way (the client is disabled in test, but the request interface code
# path is the same) and assert that credentials and bearer tokens never appear.
RSpec.describe 'Sentry configuration', type: :request do
  def event_payload_for(env)
    event = Sentry::ErrorEvent.new(configuration: Sentry.configuration)
    event.rack_env = env
    JSON.generate(event.to_json_compatible)
  end

  # Pins the effective data_collection settings so a future sentry-ruby bump (whose defaults
  # get more permissive over time) cannot silently widen what leaves the app.
  it 'collects no more than sentry-ruby 6 did, minus request payloads' do
    collection = Sentry.configuration.data_collection

    expect(collection.user_info).to be(true)
    expect(collection.url_query_params.mode).to eq(:off)
    expect(collection.cookies.mode).to eq(:off)
    expect(collection.http_bodies).to eq([])
    expect(collection.collect_incoming_http_body?).to be(false)
    expect(collection.collect_outgoing_http_body?).to be(false)
    expect(collection.database_query_data).to be(false)
    expect(collection.queues).to be(false)
    expect(collection.graphql.document).to be(false)
    expect(collection.graphql.variables).to be(false)
    expect(collection.stack_frame_variables.mode).to eq(:off)
  end

  it 'does not forward Rails structured logs to Sentry Logs' do
    expect(Sentry.configuration.rails.structured_logging.enabled?).to be(false)
  end

  it 'filters request and response headers with the Rails parameter filter terms' do
    collection = Sentry.configuration.data_collection
    # The terms from config/initializers/filter_parameter_logging.rb. (The live
    # Rails.application.config.filter_parameters can grow later, e.g. Action Text appends
    # "encrypted_rich_text.body" when its models load under eager loading.)
    rails_terms = %w[passw email secret token _key crypt salt certificate otp ssn cvv cvc]

    %i[request response].each do |direction|
      headers = collection.http_headers.public_send(direction)
      expect(headers.mode).to eq(:deny_list)
      expect(headers.terms).to include(*rails_terms)
      expect(headers.terms).to include(*Sentry::DataCollection::PII_HEADER_SNIPPETS)
    end

    env = Rack::MockRequest.env_for(
      '/',
      'HTTP_AUTHORIZATION' => 'Bearer SECRETBEARER',
      'HTTP_X_API_KEY' => 'APIKEY123',
      'HTTP_X_FORWARDED_FOR' => '203.0.113.9',
      'HTTP_X_OTP' => 'OTP654321',
      'HTTP_ACCEPT_LANGUAGE' => 'en-US'
    )
    event = Sentry::ErrorEvent.new(configuration: Sentry.configuration)
    event.rack_env = env
    headers = event.to_h.dig(:request, :headers)

    expect(headers.values).not_to include('Bearer SECRETBEARER', 'APIKEY123', 'OTP654321', '203.0.113.9')
    expect(headers['Accept-Language']).to eq('en-US')
    # The client IP still arrives through the (intended) user context, not through headers.
    expect(event.user[:ip_address]).to eq('203.0.113.9')
  end

  it 'never sends a submitted password (form or JSON body)' do
    form_env = Rack::MockRequest.env_for(
      '/users/sign_in',
      method: 'POST',
      input: 'user[email]=applicant%40example.com&user[password]=hunter2secret',
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
      'HTTP_COOKIE' => 'mmss_security_session=sessionvalue123'
    )
    json_env = Rack::MockRequest.env_for(
      '/users/sign_in',
      method: 'POST',
      input: '{"user":{"password":"hunter2secret"}}',
      'CONTENT_TYPE' => 'application/json'
    )

    [form_env, json_env].each do |env|
      payload = event_payload_for(env)
      expect(payload).not_to include('hunter2secret')
      expect(payload).not_to include('sessionvalue123')
    end
  end

  it 'never sends a Devise reset token or Nelnet callback parameters from the query string' do
    env = Rack::MockRequest.env_for(
      '/users/password/edit?reset_password_token=RESETTOKEN123&hash=NELNETSIG456&orderNumber=ORD789',
      method: 'GET'
    )

    payload = event_payload_for(env)
    expect(payload).not_to include('RESETTOKEN123')
    expect(payload).not_to include('NELNETSIG456')
    expect(payload).not_to include('ORD789')
    # The path itself is still reported, so errors remain attributable to an endpoint.
    expect(payload).to include('/users/password/edit')
  end
end
