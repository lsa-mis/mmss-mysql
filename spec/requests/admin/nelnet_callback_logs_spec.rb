# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Nelnet callback logs', type: :request do
  let(:admin) { create(:admin) }
  let!(:accepted) { create(:nelnet_callback_log, transaction_id: 'TXN-OK', order_number: 'ORD-OK', transaction_status: '1', transaction_total_amount: '25000') }
  let!(:declined) do
    create(:nelnet_callback_log, transaction_id: 'TXN-BAD', order_number: 'ORD-BAD', transaction_status: '2', transaction_total_amount: nil,
                                 raw_params: 'not json {')
  end

  before { sign_in admin }

  describe 'GET /admin/nelnet_callback_logs' do
    it 'lists callbacks with the status message and amount, without write actions' do
      get admin_nelnet_callback_logs_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('TXN-OK')
      expect(body).to include('ORD-BAD')
      expect(body).to include('Accepted credit card (successful)')
      expect(body).to include('Rejected credit card (declined)')
      expect(body).to include('$250')
      expect(body).to include(admin_nelnet_callback_log_path(accepted))
      expect(body).to include('Download CSV')
      expect(body).not_to include('With selected:')
      expect(body).not_to include('New Nelnet')
      expect(body).not_to include("/admin/nelnet_callback_logs/#{accepted.id}/edit")
    end

    it 'filters by transaction id, order number, status and date' do
      get admin_nelnet_callback_logs_path, params: { q: { transaction_id: 'OK' } }
      expect(response.body).to include(admin_nelnet_callback_log_path(accepted))
      expect(response.body).not_to include(admin_nelnet_callback_log_path(declined))

      get admin_nelnet_callback_logs_path, params: { q: { order_number: 'BAD' } }
      expect(response.body).to include(admin_nelnet_callback_log_path(declined))
      expect(response.body).not_to include(admin_nelnet_callback_log_path(accepted))

      get admin_nelnet_callback_logs_path, params: { q: { transaction_status: '2' } }
      expect(response.body).to include(admin_nelnet_callback_log_path(declined))
      expect(response.body).not_to include(admin_nelnet_callback_log_path(accepted))

      get admin_nelnet_callback_logs_path, params: { q: { created_at_to: '2000-01-01' } }
      expect(response.body).not_to include(admin_nelnet_callback_log_path(accepted))
    end

    it 'sorts by columns' do
      %w[transaction_id transaction_status transaction_total_amount nope].each do |key|
        get admin_nelnet_callback_logs_path, params: { sort: key, direction: 'desc' }
        expect(response).to have_http_status(:ok)
      end
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_nelnet_callback_logs_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                                     only_path: 'false', sort: 'transaction_id', q: { order_number: 'ORD' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/nelnet_callback_logs?')
      expect(response.body).to include('q%5Border_number%5D=ORD')
    end

    it 'paginates 30 rows per page' do
      create_list(:nelnet_callback_log, 31)

      get admin_nelnet_callback_logs_path
      expect(response.body.scan('<tr id="nelnet_callback_log_').size).to eq(30)
      expect(response.body).to include('rel="next"')

      get admin_nelnet_callback_logs_path, params: { page: 2 }
      expect(response.body).to include('Showing <span class="font-medium">31</span>–<span class="font-medium">33</span>')
    end

    it 'exports CSV' do
      get admin_nelnet_callback_logs_path(format: :csv, sort: 'transaction_id', direction: 'desc')

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Transaction ID', 'Order number', 'Transaction status', 'Total amount', 'Created at'])
      expect(csv.second[1..4]).to eq(['TXN-OK', 'ORD-OK', '1', '$250'])
      expect(csv.third[1..4]).to eq(['TXN-BAD', 'ORD-BAD', '2', nil])
    end
  end

  describe 'GET /admin/nelnet_callback_logs/:id' do
    it 'renders the fields and pretty-printed raw params' do
      get admin_nelnet_callback_log_path(accepted)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('TXN-OK')
      expect(body).to include('Accepted credit card (successful)')
      expect(body).to include('25000')
      expect(body).to include('$250')
      expect(body).to include('<pre')
      expect(CGI.unescapeHTML(body)).to include(%("transactionId": "TXN-OK"))
    end

    it 'falls back to the raw string when the params are not JSON' do
      get admin_nelnet_callback_log_path(declined)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('not json {')
    end
  end

  it 'has no write routes' do
    expect { get new_admin_nelnet_callback_log_path }.to raise_error(NameError)
    delete "/admin/nelnet_callback_logs/#{accepted.id}"
    expect(response).to have_http_status(:not_found)
    expect(NelnetCallbackLog.count).to eq(2)
  end

  it 'requires an admin' do
    sign_out admin
    get admin_nelnet_callback_logs_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
