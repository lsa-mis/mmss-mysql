# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::FinancialAidRequestsHelper, type: :helper do
  describe '#admin_financial_aid_status_options' do
    it 'returns the admin STATUS_OPTIONS for a blank status' do
      financial_aid = build_stubbed(:financial_aid, status: nil)

      expect(helper.admin_financial_aid_status_options(financial_aid))
        .to eq(Admin::FinancialAidRequestsController::STATUS_OPTIONS)
    end

    it 'appends a persisted status that is not in STATUS_OPTIONS so the select cannot clear it' do
      financial_aid = build_stubbed(:financial_aid, status: 'disbursed')

      options = helper.admin_financial_aid_status_options(financial_aid)

      expect(options).to include(*Admin::FinancialAidRequestsController::STATUS_OPTIONS)
      expect(options).to include('disbursed')
      expect(options.count('disbursed')).to eq(1)
    end

    it 'does not duplicate a status that is already in STATUS_OPTIONS' do
      financial_aid = build_stubbed(:financial_aid, status: 'pending')

      expect(helper.admin_financial_aid_status_options(financial_aid))
        .to eq(Admin::FinancialAidRequestsController::STATUS_OPTIONS)
    end
  end

  describe '#admin_agi' do
    it 'formats a reported AGI as currency' do
      expect(helper.admin_agi(52_000)).to eq('$52,000.00')
    end

    it 'returns nil when AGI is blank' do
      expect(helper.admin_agi(nil)).to be_nil
      expect(helper.admin_agi('')).to be_nil
    end
  end
end
