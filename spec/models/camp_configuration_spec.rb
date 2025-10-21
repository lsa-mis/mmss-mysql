require 'rails_helper'

RSpec.describe CampConfiguration, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:camp_occurrences).dependent(:destroy) }
    # Note: Add these associations to the model if needed:
    # it { is_expected.to have_many(:feedbacks).dependent(:destroy) }
    # it { is_expected.to have_many(:campnotes).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:camp_configuration) }

    it { is_expected.to validate_presence_of(:camp_year) }
    it { is_expected.to validate_presence_of(:application_open) }
    it { is_expected.to validate_presence_of(:application_close) }
    it { is_expected.to validate_uniqueness_of(:camp_year) }
  end

  describe 'monetize' do
    it 'monetizes application_fee' do
      config = create(:camp_configuration, application_fee_cents: 10000)
      expect(config.application_fee.cents).to eq(10000)
      expect(config.application_fee.currency).to eq(Money::Currency.new('USD'))
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      config = build(:camp_configuration)
      expect(config).to be_valid
    end

    it 'creates active config with trait' do
      config = create(:camp_configuration, :active)
      expect(config.active).to be true
    end

    it 'creates config with sessions using trait' do
      config = create(:camp_configuration, :with_sessions)
      expect(config.camp_occurrences.count).to eq(3)
    end

    it 'creates config without application fee using trait' do
      config = create(:camp_configuration, :no_application_fee)
      expect(config.application_fee_required).to be false
      expect(config.application_fee_cents).to eq(0)
    end
  end

  describe 'scopes' do
    let!(:active_config) { create(:camp_configuration, :active, camp_year: 2025) }
    let!(:inactive_config) { create(:camp_configuration, camp_year: 2024) }

    describe '.active' do
      it 'returns only active configurations' do
        expect(CampConfiguration.active).to include(active_config)
        expect(CampConfiguration.active).not_to include(inactive_config)
      end
    end

    describe '.active_camp_year' do
      it 'returns the active camp year' do
        expect(CampConfiguration.active_camp_year).to eq(2025)
      end

      it 'returns nil when no active config exists' do
        CampConfiguration.update_all(active: false)
        expect(CampConfiguration.active_camp_year).to be_nil
      end
    end
  end

  it_behaves_like 'a model with timestamps'
end
