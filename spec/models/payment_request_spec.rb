# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentRequest, type: :model do
  let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }

  before do
    CampConfiguration.update_all(active: false)
    camp_config.update!(active: true)
    allow(CampConfiguration).to receive(:active_camp_year).and_return(camp_config.camp_year)
  end

  describe 'associations' do
    it 'belongs to a user' do
      request = build(:payment_request)
      expect(request.user).to be_present
    end

    it 'optionally belongs to a payment' do
      user = create(:user)
      payment = create(:payment, user: user, camp_year: camp_config.camp_year)
      request = create(:payment_request, user: user, payment: payment)

      expect(request.payment).to eq(payment)
      expect(payment.payment_request).to eq(request)
    end
  end

  describe 'validations' do
    subject(:payment_request) { build(:payment_request) }

    it 'is valid with factory defaults' do
      expect(payment_request).to be_valid
    end

    it 'requires order_number' do
      payment_request.order_number = nil
      expect(payment_request).not_to be_valid
      expect(payment_request.errors[:order_number]).to be_present
    end

    it 'requires amount_cents' do
      payment_request.amount_cents = nil
      expect(payment_request).not_to be_valid
      expect(payment_request.errors[:amount_cents]).to be_present
    end

    it 'requires request_timestamp' do
      payment_request.request_timestamp = nil
      expect(payment_request).not_to be_valid
      expect(payment_request.errors[:request_timestamp]).to be_present
    end

    it 'rejects non-integer amount_cents' do
      payment_request.amount_cents = 10.5
      expect(payment_request).not_to be_valid
      expect(payment_request.errors[:amount_cents]).to be_present
    end

    it 'rejects negative amount_cents' do
      payment_request.amount_cents = -1
      expect(payment_request).not_to be_valid
      expect(payment_request.errors[:amount_cents]).to be_present
    end

    it 'allows zero amount_cents' do
      payment_request.amount_cents = 0
      expect(payment_request).to be_valid
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:unmatched_request) do
      create(:payment_request, user: user, camp_year: camp_config.camp_year, payment: nil)
    end
    let!(:matched_request) do
      payment = create(:payment, user: user, camp_year: camp_config.camp_year)
      create(:payment_request, user: user, camp_year: camp_config.camp_year, payment: payment)
    end
    let!(:prior_year_unmatched) do
      create(:payment_request, user: user, camp_year: camp_config.camp_year - 1, payment: nil)
    end

    describe '.unmatched' do
      it 'returns only payment requests that have not been linked to a receipt' do
        expect(described_class.unmatched).to include(unmatched_request, prior_year_unmatched)
        expect(described_class.unmatched).not_to include(matched_request)
      end
    end

    describe '.for_camp_year' do
      it 'filters by camp year used for unmatched receipt matching and admin views' do
        expect(described_class.for_camp_year(camp_config.camp_year)).to include(unmatched_request, matched_request)
        expect(described_class.for_camp_year(camp_config.camp_year)).not_to include(prior_year_unmatched)
      end
    end
  end
end
