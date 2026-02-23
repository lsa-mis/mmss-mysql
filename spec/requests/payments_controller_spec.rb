# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentsController, type: :request do
  let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
  let(:user) { create(:user, :with_applicant_detail) }
  let!(:enrollment) { create(:enrollment, user: user, campyear: camp_config.camp_year) }

  # Order number format sent to/from Nelnet: email prefix + '-' + user id
  let(:order_number) { "#{user.email.partition('@').first}-#{user.id}" }

  # Stub Nelnet credentials (QA/development)
  let(:nelnet_credentials) do
    OpenStruct.new(
      NELNET_SERVICE: {
        SERVICE_SELECTOR: 'QA',
        DEVELOPMENT_KEY: 'dev-key',
        DEVELOPMENT_URL: 'https://auth-interstitial.it.umich.edu/',
        PRODUCTION_KEY: 'prod-key',
        PRODUCTION_URL: 'https://prod.example.com/pay'
      }
    )
  end

  # Params as returned by Nelnet on GET /payment_receipt (from your FROM example)
  def nelnet_receipt_params(overrides = {})
    {
      'transactionType' => '1',
      'transactionStatus' => '1',
      'transactionId' => (overrides['transactionId'] || "TXN-#{SecureRandom.hex(4)}"),
      'transactionTotalAmount' => '10000',
      'transactionDate' => '202602230121',
      'transactionAcountType' => 'MASTERCARD',
      'transactionResultCode' => '',
      'transactionResultMessage' => 'Approved',
      'orderNumber' => order_number,
      'orderType' => 'MMSS Univ of Michigan',
      'timestamp' => '1771827677567',
      'hash' => '451b5f85a1741a0114c41c14529f47d55c18ab12d8f6ffacb06e96b6481e195a'
    }.merge(overrides.stringify_keys)
  end

  before do
    CampConfiguration.update_all(active: false)
    camp_config.update(active: true)
    allow(CampConfiguration).to receive(:active_camp_year).and_return(camp_config.camp_year)
    allow(CampConfiguration).to receive(:active).and_return(CampConfiguration.where(id: camp_config.id))
    allow_any_instance_of(ApplicationHelper).to receive(:current_camp_fee).and_return(camp_config.application_fee_cents)
    allow_any_instance_of(ApplicationHelper).to receive(:registration_open?).and_return(false)
    allow_any_instance_of(ApplicationHelper).to receive(:new_registration_closed?).and_return(false)
    allow_any_instance_of(PaymentsController).to receive(:total_cost).and_return(0)
  end

  # ---------------------------------------------------------------------------
  # Payment cycle: make_payment (outbound TO Nelnet)
  # ---------------------------------------------------------------------------
  describe 'make_payment (outbound to Nelnet)' do
    before do
      sign_in user
      allow(Rails.application).to receive(:credentials).and_return(nelnet_credentials)
    end

    context 'POST /make_payment' do
      it 'creates a PaymentRequest and redirects to Nelnet URL with correct query params' do
        expect {
          post make_payment_path, params: { amount: '100' }
        }.to change(PaymentRequest, :count).by(1)

        expect(response).to have_http_status(:found)
        location = response.headers['Location']
        expect(location).to start_with('https://auth-interstitial.it.umich.edu/?')
        expect(location).to include("orderNumber=#{CGI.escape(order_number)}")
        expect(location).to include('orderType=')
        expect(location).to include('MMSS')
        expect(location).to include('Michigan')
        expect(location).to include('orderDescription=')
        expect(location).to include('Conference')
        expect(location).to include('Fees')
        expect(location).to include('amountDue=10000')  # 100 dollars -> 10000 cents
        expect(location).to include('redirectUrlParameters=')
        expect(location).to include('transactionType')
        expect(location).to include('orderNumber')
        expect(location).to include('timestamp=')
        expect(location).to include('hash=')
      end

      it 'stores PaymentRequest with user_id, order_number, amount_cents, camp_year, request_timestamp' do
        post make_payment_path, params: { amount: '100' }

        pr = PaymentRequest.last
        expect(pr.user_id).to eq(user.id)
        expect(pr.order_number).to eq(order_number)
        expect(pr.amount_cents).to eq(10_000)
        expect(pr.camp_year).to eq(camp_config.camp_year)
        expect(pr.request_timestamp).to be_a(Integer)
        expect(pr.payment_id).to be_nil
      end

      it 'uses amount in dollars and sends amountDue in cents (e.g. 100 -> 10000)' do
        post make_payment_path, params: { amount: '50' }
        location = response.headers['Location']
        expect(location).to include('amountDue=5000')
        expect(PaymentRequest.last.amount_cents).to eq(5000)
      end
    end

    context 'GET /make_payment' do
      it 'creates a PaymentRequest and redirects to Nelnet URL with hash and required params' do
        expect {
          get make_payment_path, params: { amount: 123 }
        }.to change(PaymentRequest, :count).by(1)

        expect(response).to have_http_status(:found)
        location = response.headers['Location']
        expect(location).to include('https://auth-interstitial.it.umich.edu/?')
        expect(location).to include('orderNumber=')
        expect(location).to include('amountDue=12300')
        expect(location).to include('hash=')
      end
    end

  end

  describe 'make_payment when not authenticated' do
    before { allow(Rails.application).to receive(:credentials).and_return(nelnet_credentials) }

    it 'redirects to sign-in and does not create PaymentRequest' do
      get make_payment_path, params: { amount: '100' }
      expect(response).to have_http_status(:found)
      expect(response.location).to include('sign_in')
      expect(PaymentRequest.count).to eq(0)
    end
  end

  # ---------------------------------------------------------------------------
  # Payment cycle: payment_receipt (inbound FROM Nelnet)
  # ---------------------------------------------------------------------------
  describe 'payment_receipt (inbound from Nelnet)' do
    before { sign_in user }

    context 'when transaction is successful (transactionStatus=1)' do
      it 'creates a Payment and redirects with success notice (POST)' do
        allow_any_instance_of(Payment).to receive(:set_status).and_return(nil)
        params = nelnet_receipt_params('transactionId' => '432051518')

        expect {
          post payment_receipt_path, params: params
        }.to change(Payment, :count).by(1)

        expect(response).to redirect_to(all_payments_path)
        follow_redirect!
        expect(response.body).to include('successfully recorded')

        payment = Payment.find_by(transaction_id: '432051518')
        expect(payment).to be_present
        expect(payment.transaction_type).to eq('1')
        expect(payment.transaction_status).to eq('1')
        expect(payment.total_amount).to eq('10000')
        expect(payment.user_account).to eq(order_number)
        expect(payment.user_id).to eq(user.id)
        expect(payment.camp_year).to eq(camp_config.camp_year)
      end

      it 'creates a Payment and redirects with success notice (GET, as Nelnet redirects)' do
        allow_any_instance_of(Payment).to receive(:set_status).and_return(nil)
        params = nelnet_receipt_params('transactionId' => '432051519')

        expect {
          get payment_receipt_path, params: params
        }.to change(Payment, :count).by(1)

        expect(response).to redirect_to(all_payments_path)
        follow_redirect!
        expect(response.body).to include('successfully recorded')
      end
    end

    context 'when transaction failed (transactionStatus != 1)' do
      it 'creates a Payment with failed status and redirects with alert' do
        allow_any_instance_of(Payment).to receive(:set_status).and_return(nil)
        params = nelnet_receipt_params(
          'transactionStatus' => '0',
          'transactionResultMessage' => 'Declined'
        )

        expect {
          post payment_receipt_path, params: params
        }.to change(Payment, :count).by(1)

        expect(response).to redirect_to(all_payments_path)
        follow_redirect!
        expect(response.body).to include('not successful')

        payment = Payment.last
        expect(payment.transaction_status).to eq('0')
      end
    end

    context 'duplicate transactionId' do
      it 'does not create a second Payment and redirects to all_payments' do
        allow_any_instance_of(Payment).to receive(:set_status).and_return(nil)
        params = nelnet_receipt_params('transactionId' => 'dup-123')

        post payment_receipt_path, params: params
        expect(response).to redirect_to(all_payments_path)
        expect(Payment.count).to eq(1)

        expect(Payment).not_to receive(:create)
        get payment_receipt_path, params: params
        expect(response).to redirect_to(all_payments_path)
        expect(Payment.count).to eq(1)
      end
    end

    context 'Nelnet callback log' do
      it 'creates a NelnetCallbackLog for every request to payment_receipt' do
        allow_any_instance_of(Payment).to receive(:set_status).and_return(nil)
        params = nelnet_receipt_params('transactionId' => 'log-test-1')

        expect {
          post payment_receipt_path, params: params
        }.to change(NelnetCallbackLog, :count).by(1)

        log = NelnetCallbackLog.last
        expect(log.transaction_id).to eq('log-test-1')
        expect(log.order_number).to eq(order_number)
        expect(log.transaction_status).to eq('1')
        expect(log.transaction_total_amount).to eq('10000')
        expect(log.raw_params).to be_present
        parsed = JSON.parse(log.raw_params)
        expect(parsed['transactionId']).to eq('log-test-1')
        expect(parsed['orderNumber']).to eq(order_number)
      end

      it 'creates a callback log even on duplicate transactionId (second request)' do
        allow_any_instance_of(Payment).to receive(:set_status).and_return(nil)
        params = nelnet_receipt_params('transactionId' => 'dup-callback')

        post payment_receipt_path, params: params
        expect(NelnetCallbackLog.count).to eq(1)

        get payment_receipt_path, params: params
        expect(NelnetCallbackLog.count).to eq(2)
        expect(NelnetCallbackLog.pluck(:transaction_id)).to all(eq('dup-callback'))
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Full payment cycle: request → redirect → return from Nelnet → Payment + link
  # ---------------------------------------------------------------------------
  describe 'full payment cycle (request → receipt → link)' do
    before do
      sign_in user
      allow(Rails.application).to receive(:credentials).and_return(nelnet_credentials)
      allow_any_instance_of(Payment).to receive(:set_status).and_return(nil)
    end

    it 'links PaymentRequest to Payment when user returns from Nelnet with matching orderNumber' do
      # 1. User initiates payment (TO Nelnet)
      post make_payment_path, params: { amount: '100' }
      expect(response).to have_http_status(:found)
      pr = PaymentRequest.last
      expect(pr.payment_id).to be_nil

      # 2. User returns from Nelnet (FROM Nelnet) with success params
      receipt_params = nelnet_receipt_params(
        'transactionId' => '432051518',
        'orderNumber' => order_number
      )
      get payment_receipt_path, params: receipt_params

      expect(Payment.count).to eq(1)
      payment = Payment.find_by(transaction_id: '432051518')
      expect(payment.user_account).to eq(order_number)

      # 3. PaymentRequest should now be linked to Payment
      pr.reload
      expect(pr.payment_id).to eq(payment.id)
      expect(payment.payment_request).to eq(pr)
    end

    it 'on duplicate return (same transactionId), does not create second Payment but still links PaymentRequest if not yet linked' do
      post make_payment_path, params: { amount: '100' }
      pr = PaymentRequest.last

      receipt_params = nelnet_receipt_params('transactionId' => '432051520', 'orderNumber' => order_number)
      get payment_receipt_path, params: receipt_params
      expect(Payment.count).to eq(1)
      pr.reload
      expect(pr.payment_id).to eq(Payment.last.id)

      # Second hit with same transactionId (e.g. user refreshed)
      get payment_receipt_path, params: receipt_params
      expect(Payment.count).to eq(1)
      pr.reload
      expect(pr.payment_id).to eq(Payment.last.id)
    end

    it 'links oldest unmatched PaymentRequest when multiple exist for same order_number' do
      # Two payment attempts (e.g. user clicked Pay twice)
      post make_payment_path, params: { amount: '100' }
      first_pr = PaymentRequest.last
      post make_payment_path, params: { amount: '100' }
      second_pr = PaymentRequest.last
      expect(PaymentRequest.unmatched.count).to eq(2)

      # One return from Nelnet
      receipt_params = nelnet_receipt_params('transactionId' => 'single-return', 'orderNumber' => order_number)
      get payment_receipt_path, params: receipt_params

      first_pr.reload
      second_pr.reload
      expect(first_pr.payment_id).to eq(Payment.last.id)
      expect(second_pr.payment_id).to be_nil
    end
  end

  # ---------------------------------------------------------------------------
  # payment_show and index (existing behavior)
  # ---------------------------------------------------------------------------
  describe 'GET /payment_show (all_payments)' do
    context 'when signed in' do
      before { sign_in user }

      it 'renders successfully' do
        get all_payments_path
        expect(response).to have_http_status(:ok)
      end
    end

    it 'redirects to sign-in when not authenticated' do
      get all_payments_path
      expect(response).to have_http_status(:found)
      expect(response.location).to include('sign_in')
    end
  end

  describe 'GET /payments (index)' do
    it 'requires admin for index' do
      sign_in user
      get payments_path
      expect(response).to redirect_to('/admin/login')
    end
  end

  # ---------------------------------------------------------------------------
  # Edge cases: unauthenticated callback, callback log before auth
  # ---------------------------------------------------------------------------
  describe 'payment_receipt when not authenticated' do
    it 'creates NelnetCallbackLog then redirects to sign-in (callback is logged before auth)' do
      params = nelnet_receipt_params('transactionId' => 'no-auth-1')
      expect {
        get payment_receipt_path, params: params
      }.to change(NelnetCallbackLog, :count).by(1)

      expect(response).to have_http_status(:found)
      expect(response.location).to include('sign_in')
      expect(Payment.count).to eq(0)

      log = NelnetCallbackLog.last
      expect(log.transaction_id).to eq('no-auth-1')
      expect(log.order_number).to eq(order_number)
    end
  end
end
