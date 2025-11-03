# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentState, type: :model do
  let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year, application_fee_cents: 2000) }
  let(:user) { create(:user, :with_applicant_detail) }
  let!(:enrollment) { create(:enrollment, user: user, campyear: camp_config.camp_year) }

  before do
    CampConfiguration.update_all(active: false)
    camp_config.update(active: true)
    allow(CampConfiguration).to receive(:active_camp_year).and_return(camp_config.camp_year)
    allow(CampConfiguration).to receive(:active).and_return(CampConfiguration.where(id: camp_config.id))
  end

  subject(:state) { described_class.new(enrollment) }

  describe '#ttl_paid' do
    it 'sums only successful current camp payments' do
      create(:payment, user: user, camp_year: camp_config.camp_year, transaction_status: '1', total_amount: '1000')
      create(:payment, user: user, camp_year: camp_config.camp_year, transaction_status: '0', total_amount: '9999')
      create(:payment, user: user, camp_year: camp_config.camp_year - 1, transaction_status: '1', total_amount: '2000')
      expect(state.ttl_paid).to eq(1000)
    end
  end

  describe '#total_cost' do
    let!(:session1) { create(:camp_occurrence, cost_cents: 5000) }
    let!(:session2) { create(:camp_occurrence, cost_cents: 7000) }

    before do
      # Assign accepted sessions
      create(:session_assignment, enrollment: enrollment, camp_occurrence: session1, offer_status: 'accepted')
      create(:session_assignment, enrollment: enrollment, camp_occurrence: session2, offer_status: 'accepted')
    end

    it 'includes application fee when required' do
      enrollment.update!(application_fee_required: true)
      # No activities added in this test
      expect(state.total_cost).to eq(5000 + 7000 + camp_config.application_fee_cents)
    end

    it 'excludes application fee when not required' do
      enrollment.update!(application_fee_required: false)
      expect(state.total_cost).to eq(5000 + 7000)
    end
  end

  describe '#balance_due' do
    it 'computes total_cost - awarded aid - ttl_paid' do
      # Make cost simple by stubbing total_cost
      allow(state).to receive(:total_cost).and_return(10_000)
      allow_any_instance_of(FinancialAid).to receive(:send_status_watch_email).and_return(nil)
      create(:financial_aid, enrollment: enrollment, amount_cents: 1500, status: 'awarded')
      create(:financial_aid, enrollment: enrollment, amount_cents: 2000, status: 'pending')
      create(:payment, user: user, camp_year: camp_config.camp_year, transaction_status: '1', total_amount: '2500')

      expect(state.balance_due).to eq(10_000 - 1500 - 2500)
    end
  end
end
