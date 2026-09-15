# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAidsController, type: :controller do
  describe '#financial_aid_params' do
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let!(:enrollment) { create(:enrollment, user: user, campyear: camp_config.camp_year) }

    let(:raw_params) do
      ActionController::Parameters.new(
        financial_aid: {
          note: 'Need assistance with tuition',
          adjusted_gross_income: 45_000,
          amount_cents: 99_999,
          status: 'awarded',
          source: 'Self-awarded',
          payments_deadline: Date.current.to_s
        }
      )
    end

    before do
      CampConfiguration.update_all(active: false)
      camp_config.update!(active: true)
      allow(controller).to receive(:params).and_return(raw_params)
    end

    it 'omits admin-only fields for applicants' do
      sign_in user
      allow(controller).to receive(:admin_signed_in?).and_return(false)

      permitted = controller.send(:financial_aid_params)

      expect(permitted.to_h).to eq(
        'note' => 'Need assistance with tuition',
        'adjusted_gross_income' => 45_000
      )
      expect(permitted.keys.map(&:to_s)).not_to include(
        'amount_cents', 'status', 'source', 'payments_deadline'
      )
    end

    it 'allows admin-only fields when an admin is signed in' do
      sign_in admin
      allow(controller).to receive(:admin_signed_in?).and_return(true)

      permitted = controller.send(:financial_aid_params)

      expect(permitted.to_h).to include(
        'note' => 'Need assistance with tuition',
        'adjusted_gross_income' => 45_000,
        'amount_cents' => 99_999,
        'status' => 'awarded',
        'source' => 'Self-awarded',
        'payments_deadline' => Date.current.to_s
      )
    end
  end
end
