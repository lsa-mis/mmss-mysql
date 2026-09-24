# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin payment requests', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, email: 'payer@example.com') }
  let(:payment) { create(:payment, user: user, transaction_id: 'TXN-MATCHED') }
  let!(:matched) { create(:payment_request, user: user, order_number: 'ORD-1', amount_cents: 12_345, camp_year: 2031, payment: payment) }
  let!(:unmatched) { create(:payment_request, user: create(:user, email: 'other@example.com'), order_number: 'ORD-2', amount_cents: 500, camp_year: 2030) }

  before { sign_in admin }

  describe 'GET /admin/payment_requests' do
    it 'lists requests with amounts, timestamps, match status and scopes, without edit/delete' do
      get admin_payment_requests_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('payer@example.com')
      expect(body).to include('ORD-1')
      expect(body).to include('$123.45')
      expect(body).to include('$5')
      expect(body).to include("Payment ##{payment.id}")
      expect(body).to include('Unmatched')
      expect(body).to include(admin_payment_request_path(matched))
      expect(body).to include('Download CSV')
      expect(body).not_to include('With selected:')
      expect(body).not_to include('New Payment Request')
      expect(body).not_to include("/admin/payment_requests/#{matched.id}/edit")
      # Feb 2026, the factory's epoch-ms request timestamp
      expect(body).to include('Feb')
    end

    it 'scopes to unmatched requests' do
      get admin_payment_requests_path, params: { scope: 'unmatched' }

      expect(response.body).to include(admin_payment_request_path(unmatched))
      expect(response.body).not_to include(admin_payment_request_path(matched))
    end

    it 'filters by user, order number, camp year, matched payment and date' do
      get admin_payment_requests_path, params: { q: { user_id: user.id } }
      expect(response.body).to include(admin_payment_request_path(matched))
      expect(response.body).not_to include(admin_payment_request_path(unmatched))

      get admin_payment_requests_path, params: { q: { order_number: 'ORD-2' } }
      expect(response.body).to include(admin_payment_request_path(unmatched))
      expect(response.body).not_to include(admin_payment_request_path(matched))

      get admin_payment_requests_path, params: { q: { camp_year: '2030' } }
      expect(response.body).to include(admin_payment_request_path(unmatched))
      expect(response.body).not_to include(admin_payment_request_path(matched))

      get admin_payment_requests_path, params: { q: { payment_id: payment.id } }
      expect(response.body).to include(admin_payment_request_path(matched))
      expect(response.body).not_to include(admin_payment_request_path(unmatched))
      expect(response.body).to include('TXN-MATCHED (')

      get admin_payment_requests_path, params: { q: { created_at_to: '2000-01-01' } }
      expect(response.body).not_to include(admin_payment_request_path(matched))
    end

    it 'sorts by user through the join and by columns' do
      %w[user amount request_timestamp payment nope].each do |key|
        get admin_payment_requests_path, params: { sort: key, direction: 'desc' }
        expect(response).to have_http_status(:ok)
      end
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_payment_requests_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                                 only_path: 'false', sort: 'amount', scope: 'unmatched', q: { order_number: 'ORD' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/payment_requests?')
      expect(response.body).to include('q%5Border_number%5D=ORD')
      expect(response.body).to include('scope=all')
    end

    it 'paginates 30 rows per page' do
      31.times { |i| create(:payment_request, user: user, order_number: "BULK-#{i}") }

      get admin_payment_requests_path
      expect(response.body.scan('<tr id="payment_request_').size).to eq(30)
      expect(response.body).to include('rel="next"')

      get admin_payment_requests_path, params: { page: 2 }
      expect(response.body).to include('Showing <span class="font-medium">31</span>–<span class="font-medium">33</span>')
    end

    it 'exports CSV' do
      get admin_payment_requests_path(format: :csv, sort: 'order_number', direction: 'asc')

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'User', 'Order number', 'Amount', 'Camp year', 'Request time', 'Matched payment', 'Created at'])
      expect(csv.second[1..4]).to eq(['payer@example.com', 'ORD-1', '$123.45', '2031'])
      expect(csv.second[6]).to eq(payment.id.to_s)
    end
  end

  describe 'GET /admin/payment_requests/:id' do
    it 'renders cents, dollars, raw and parsed timestamps and the payment link' do
      get admin_payment_request_path(matched)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('12345')
      expect(body).to include('$123.45')
      expect(body).to include('1771827677567')
      expect(body).to include("Payment ##{payment.id}")
      expect(body).to include('ORD-1')
    end

    it 'shows unmatched requests as such' do
      get admin_payment_request_path(unmatched)

      expect(response.body).to include('Unmatched')
    end
  end

  it 'has no write routes' do
    expect { get new_admin_payment_request_path }.to raise_error(NameError)
    delete "/admin/payment_requests/#{matched.id}"
    expect(response).to have_http_status(:not_found)
    expect(PaymentRequest.count).to eq(2)
  end

  it 'requires an admin' do
    sign_out admin
    get admin_payment_requests_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
