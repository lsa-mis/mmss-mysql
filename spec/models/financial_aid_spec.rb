# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAid, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:enrollment) }
  end

  describe 'validations' do
    subject { build(:financial_aid) }

    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe 'monetize' do
    it 'monetizes amount' do
      aid = create(:financial_aid, amount_cents: 100000)
      expect(aid.amount.cents).to eq(100000)
      expect(aid.amount.currency).to eq(Money::Currency.new('USD'))
    end
  end

  describe 'attachments' do
    it { is_expected.to have_one_attached(:taxform) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      aid = build(:financial_aid)
      expect(aid).to be_valid
    end

    it 'creates approved aid with trait' do
      aid = create(:financial_aid, :approved)
      expect(aid.status).to eq('approved')
    end

    it 'creates full scholarship with trait' do
      aid = create(:financial_aid, :full_scholarship)
      expect(aid.amount_cents).to eq(200000)
      expect(aid.status).to eq('approved')
    end

    it 'creates aid with taxform using trait' do
      aid = create(:financial_aid, :with_taxform)
      expect(aid.taxform).to be_attached
    end
  end

  describe 'scopes' do
    let(:enrollment) { create(:enrollment, campyear: Date.current.year) }
    let!(:current_aid) { create(:financial_aid, enrollment: enrollment) }

    let(:old_enrollment) { create(:enrollment, campyear: Date.current.year - 1) }
    let!(:old_aid) { create(:financial_aid, enrollment: old_enrollment) }

    before do
      # Ensure the current year's camp configuration is active
      current_camp_config = CampConfiguration.find_by(camp_year: Date.current.year)
      if current_camp_config
        CampConfiguration.update_all(active: false)
        current_camp_config.update!(active: true)
      end
    end

    describe '.current_camp_requests' do
      it 'returns financial aid for current camp year' do
        expect(FinancialAid.current_camp_requests).to include(current_aid)
        expect(FinancialAid.current_camp_requests).not_to include(old_aid)
      end
    end
  end

  it_behaves_like 'a model with timestamps'
end
