# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentsController, type: :request do
  let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
  let(:user) { create(:user, :with_applicant_detail) }
  let!(:enrollment) { create(:enrollment, user: user, campyear: camp_config.camp_year) }

  before do
    # Ensure active camp
    CampConfiguration.update_all(active: false)
    camp_config.update(active: true)
    allow(CampConfiguration).to receive(:active_camp_year).and_return(camp_config.camp_year)
    # Ensure views that call CampConfiguration.active behave consistently
    allow(CampConfiguration).to receive(:active).and_return(CampConfiguration.where(id: camp_config.id))
    # Avoid layout/helper dependencies causing view errors in request specs
    allow_any_instance_of(ApplicationHelper).to receive(:current_camp_fee).and_return(camp_config.application_fee_cents)
    allow_any_instance_of(ApplicationHelper).to receive(:registration_open?).and_return(false)
    allow_any_instance_of(ApplicationHelper).to receive(:new_registration_closed?).and_return(false)
    # Avoid dependence on ApplicantState total_cost composition in controller specs
    allow_any_instance_of(PaymentsController).to receive(:total_cost).and_return(0)
  end

  describe 'POST /payment_receipt' do
    before { sign_in user }

    let(:base_params) do
      {
        'transactionType' => '1',
        'transactionStatus' => '1',
        'transactionId' => "TXN-#{SecureRandom.hex(4)}",
        'transactionTotalAmount' => '10000',
        'transactionDate' => DateTime.current.strftime('%Y%m%d%H%M'),
        'transactionAcountType' => 'credit_card',
        'transactionResultCode' => '0',
        'transactionResultMessage' => 'Success',
        'orderNumber' => 'ORDER-1',
        'timestamp' => DateTime.now.to_i.to_s,
        'hash' => 'dummy'
      }
    end

    it 'creates a payment and redirects with success notice when status is 1' do
      # Avoid side effects from callbacks in controller-level spec
      allow_any_instance_of(Payment).to receive(:set_status).and_return(nil)
      expect(Payment).to receive(:create).with(hash_including(
        transaction_type: '1',
        transaction_status: '1',
        transaction_id: a_kind_of(String),
        total_amount: '10000',
        user_id: user.id,
        camp_year: camp_config.camp_year
      )).and_call_original

      post payment_receipt_path, params: base_params
      expect(response).to redirect_to(all_payments_path)
      follow_redirect!
      expect(response.body).to include('successfully recorded')
    end

    it 'does not create a duplicate payment for same transactionId' do
      allow_any_instance_of(Payment).to receive(:set_status).and_return(nil)
      post payment_receipt_path, params: base_params
      expect(response).to redirect_to(all_payments_path)

      # Second post with same transactionId should not call create
      expect(Payment).not_to receive(:create)
      post payment_receipt_path, params: base_params
      expect(response).to redirect_to(all_payments_path)
    end

    it 'creates a failed payment and shows alert when status is not 1' do
      allow_any_instance_of(Payment).to receive(:set_status).and_return(nil)
      params = base_params.merge('transactionStatus' => '0', 'transactionResultMessage' => 'Failure')

      expect(Payment).to receive(:create).with(hash_including(transaction_status: '0')).and_call_original
      post payment_receipt_path, params: params

      expect(response).to redirect_to(all_payments_path)
      follow_redirect!
      expect(response.body).to include('not successfull')
    end
  end

  describe 'GET /payment_show' do
    context 'when signed in' do
      before { sign_in user }

      it 'renders successfully' do
        # Ensure guard clause passes and current enrollment is present
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

  describe 'GET /make_payment' do
    before { sign_in user }

    it 'redirects to gateway URL with hash and required params (QA)' do
      # Stub credentials for QA selector
      allow(Rails.application).to receive(:credentials).and_return(
        OpenStruct.new(
          NELNET_SERVICE: {
            SERVICE_SELECTOR: 'QA',
            DEVELOPMENT_KEY: 'dev-key',
            DEVELOPMENT_URL: 'https://qa.example.com/pay',
            PRODUCTION_KEY: 'prod-key',
            PRODUCTION_URL: 'https://prod.example.com/pay'
          }
        )
      )

      get make_payment_path, params: { amount: 123 }
      expect(response).to have_http_status(:found)
      location = response.headers['Location']
      expect(location).to include('https://qa.example.com/pay?')
      expect(location).to include('orderNumber=')
      expect(location).to include('amountDue=12300')
      expect(location).to include('hash=')
    end
  end

  describe 'GET /payments (index)' do
    it 'requires admin for index' do
      sign_in user
      get payments_path
      # Non-admins are redirected to ActiveAdmin login
      expect(response).to redirect_to('/admin/login')
    end
  end
end
