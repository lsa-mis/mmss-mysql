# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin payments', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let!(:enrollment) { create(:enrollment, :accepted, user: user) }
  # transaction_status '2' keeps Payment#set_status from touching the application in the setup.
  let!(:payment) do
    create(:payment, user: user, camp_year: enrollment.campyear, total_amount: '25050', transaction_status: '2',
                     transaction_id: 'TXN-ZIM-1', account_type: 'credit_card', result_message: 'Declined',
                     payer_identity: user.email, transaction_hash: 'abc123hash')
  end

  before do
    user.applicant_detail.update!(lastname: 'Zimmerman', firstname: 'Ada')
    sign_in admin
  end

  it 'requires an admin' do
    sign_out admin

    get admin_payments_path

    expect(response).to redirect_to(new_admin_session_path)
  end

  describe 'GET /admin/payments' do
    it 'lists payments with the ActiveAdmin columns, filters and view/edit actions but no delete or batch actions' do
      get admin_payments_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(user.email)
      expect(body).to include('TXN-ZIM-1')
      expect(body).to include('$250.50')
      expect(body).to include('Rejected credit card (declined)')
      expect(body).to include('credit_card')
      expect(body).to include(edit_admin_payment_path(payment))
      expect(body).to include('New Payment')
      expect(body).to include('Download CSV')
      expect(body).to include('Account type')
      expect(body).not_to include('With selected:')
      expect(body).not_to include('>Delete<')
      expect(body).not_to include('abc123hash')
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_payments_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                         only_path: 'false', sort: 'created_at', q: { account_type: 'credit_card' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/payments?')
      expect(response.body).to include('direction=asc')
      expect(response.body).to include('q%5Baccount_type%5D=credit_card')
    end

    it 'filters by user, account type, camp year and created_at range' do
      other_user = create(:user, :with_applicant_detail)
      other_user.applicant_detail.update!(lastname: 'Anderson')
      create(:payment, user: other_user, camp_year: 1999, account_type: 'bank_transfer', transaction_status: '2',
                       created_at: Time.zone.local(1999, 6, 1))

      get admin_payments_path, params: { q: { user_id: user.id } }
      expect(response.body).to include('Zimmerman')
      expect(response.body).not_to include('Anderson')
      expect(response.body).to include('1 active filter')

      get admin_payments_path, params: { q: { account_type: 'bank_transfer' } }
      expect(response.body).to include('Anderson')
      expect(response.body).not_to include('Zimmerman')

      get admin_payments_path, params: { q: { camp_year: 1999 } }
      expect(response.body).to include('Anderson')
      expect(response.body).not_to include('Zimmerman')

      get admin_payments_path, params: { q: { created_at_from: '1999-01-01', created_at_to: '1999-12-31' } }
      expect(response.body).to include('Anderson')
      expect(response.body).not_to include('Zimmerman')
    end

    it 'sorts by an allowed column (including the numeric amount cast) and ignores unknown ones' do
      get admin_payments_path, params: { sort: 'total_amount', direction: 'asc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('direction=desc')

      get admin_payments_path, params: { sort: 'user', direction: 'asc' }
      expect(response).to have_http_status(:ok)

      get admin_payments_path, params: { sort: 'drop table', direction: 'asc' }
      expect(response).to have_http_status(:ok)
    end

    it 'renders pagination links when there is more than one page' do
      32.times { |i| create(:payment, user: user, transaction_status: '2', transaction_id: "TXN-PAGE-#{i}") }

      get admin_payments_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Showing <span class="font-medium">1</span>–<span class="font-medium">30</span>')
      expect(response.body).to include('of <span class="font-medium">33</span>')
      expect(response.body).to include('href="/admin/payments?page=2"')
      expect(response.body).to include('rel="next"')

      get admin_payments_path, params: { page: 2, limit: 1 }
      expect(response.body).to include('Showing <span class="font-medium">2</span>–<span class="font-medium">2</span>')
      expect(response.body).to include('rel="prev"')
    end

    it 'exports CSV with the name/email/status message columns, a formatted amount and no transaction hash' do
      get admin_payments_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('MMSS-payments-')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(
        ['Id', 'User', 'email', 'Transaction type', 'Transaction status', 'Transaction status message', 'Transaction id',
         'Total amount', 'Transaction date', 'Account type', 'Result code', 'Result message', 'User account',
         'Payer identity', 'Timestamp', 'Camp year', 'Created at', 'Updated at']
      )
      row = csv.second
      expect(row[1]).to eq('Zimmerman, Ada')
      expect(row[2]).to eq(user.email)
      expect(row[5]).to eq('Rejected credit card (declined)')
      expect(row[7]).to eq('$250.50')
      expect(response.body).not_to include('abc123hash')
    end
  end

  describe 'GET /admin/payments/:id' do
    it 'renders the payment, the applicant link and the payment request panel' do
      request = create(:payment_request, user: user, payment: payment, camp_year: enrollment.campyear)

      get admin_payment_path(payment)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include("Payment ##{payment.id}")
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include('Rejected credit card (declined)')
      expect(body).to include('$250.50')
      expect(body).to include(request.order_number)
      expect(body).to include('Payment request')
      expect(body).not_to include('Add a comment')
      expect(body).not_to include('>Delete<')
    end

    it 'says so when the payment is not matched to a payment request' do
      get admin_payment_path(payment)

      expect(response.body).to include('Not matched to a Nelnet payment request')
    end
  end

  describe 'GET /admin/payments/new' do
    it 'pre-fills the manual payment defaults and shows the applicant select' do
      get new_admin_payment_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('name="payment[user_id]"')
      expect(body).to include('<option value="' + user.id.to_s + '">Zimmerman, Ada - ' + user.email + '</option>')
      expect(body).to include('name="payment[transaction_type]"')
      expect(body).to include('value="1"')
      expect(body).to include("value=\"#{enrollment.campyear}\"")
      expect(body).to match(/value="\d{12}"[^>]*name="payment\[transaction_date\]"/)
    end

    it 'prefills the applicant from ?enrollment_id= and hides the select' do
      get new_admin_payment_path(enrollment_id: enrollment.id)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(%(type="hidden" value="#{user.id}" name="payment[user_id]"))
      expect(body).not_to include('<select')
      expect(body).to include('Back to application')
    end
  end

  describe 'POST /admin/payments' do
    let(:valid_params) do
      { user_id: user.id, total_amount_dollars: '150.25', transaction_id: 'CHECK-42', account_type: 'check',
        result_message: 'Paid by check', transaction_type: '1', transaction_status: '1',
        transaction_date: '202601011200', camp_year: enrollment.campyear }
    end

    it 'records a manual payment in cents and runs the payment status callbacks' do
      expect do
        post admin_payments_path, params: { payment: valid_params }
      end.to change(Payment, :count).by(1)

      created = Payment.find_by(transaction_id: 'CHECK-42')
      expect(response).to redirect_to(admin_payment_path(created))
      expect(created.total_amount).to eq('15025')
      expect(created.total_amount_dollars).to eq(150.25)
      expect(created.user).to eq(user)
      expect(created.transaction_status).to eq('1')
      expect(created.camp_year).to eq(enrollment.campyear)
      follow_redirect!
      expect(response.body).to include('Payment was successfully created.')
    end

    it 'ignores Nelnet-only payload fields even when submitted' do
      post admin_payments_path, params: { payment: valid_params.merge(transaction_hash: 'forged', payer_identity: 'x@y.z',
                                                                       user_account: 'acct', result_code: '9',
                                                                       timestamp: '123') }

      created = Payment.find_by(transaction_id: 'CHECK-42')
      expect(created.transaction_hash).to be_nil
      expect(created.payer_identity).to be_nil
      expect(created.user_account).to be_nil
      expect(created.result_code).to be_nil
      expect(created.timestamp).to be_nil
    end

    it 're-renders the form when the applicant id does not exist' do
      post admin_payments_path, params: { payment: valid_params.merge(user_id: 999_999) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('User must exist')
    end

    it 're-renders the form with errors when invalid' do
      post admin_payments_path, params: { payment: valid_params.merge(transaction_id: payment.transaction_id) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('1 error prevented this record from being saved')
      expect(response.body).to include('Transaction has already been taken')
    end
  end

  describe 'GET /admin/payments/:id/edit' do
    it 'shows type, status, date and camp year read-only' do
      get edit_admin_payment_path(payment)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('name="payment[total_amount_dollars]"')
      expect(body).to include('value="250.5"')
      expect(body).not_to include('name="payment[transaction_type]"')
      expect(body).not_to include('name="payment[transaction_status]"')
      expect(body).not_to include('name="payment[camp_year]"')
      expect(body).to include('Fixed once the payment is recorded.')
    end
  end

  describe 'PATCH /admin/payments/:id' do
    it 'updates the editable fields and leaves type/status/date/camp year alone' do
      patch admin_payment_path(payment), params: { payment: { total_amount_dollars: '300', result_message: 'Corrected',
                                                              transaction_status: '1', camp_year: 1990, transaction_type: '9' } }

      expect(response).to redirect_to(admin_payment_path(payment))
      payment.reload
      expect(payment.total_amount).to eq('30000')
      expect(payment.result_message).to eq('Corrected')
      expect(payment.transaction_status).to eq('2')
      expect(payment.transaction_type).to eq('1')
      expect(payment.camp_year).to eq(enrollment.campyear)
    end

    it 're-renders the form with errors when invalid' do
      patch admin_payment_path(payment), params: { payment: { total_amount_dollars: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include("Total amount can't be blank")
    end
  end

  describe 'destroy' do
    it 'has no route in the admin' do
      delete "/admin/payments/#{payment.id}"

      expect(response).not_to have_http_status(:ok)
      expect(Payment.exists?(payment.id)).to be(true)
    end
  end

  describe 'public routes' do
    it 'no longer has the admin-only /payments index' do
      get '/payments'

      expect(response).to have_http_status(:not_found)
    end
  end
end
