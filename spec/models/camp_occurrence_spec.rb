require 'rails_helper'

RSpec.describe CampOccurrence, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:camp_configuration) }
    it { is_expected.to have_many(:courses).dependent(:destroy) }
    it { is_expected.to have_many(:activities).dependent(:destroy) }
    it { is_expected.to have_many(:session_activities).dependent(:destroy) }
    it { is_expected.to have_many(:session_assignments).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:camp_occurrence) }

    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:begin_date) }
    it { is_expected.to validate_presence_of(:end_date) }
  end

  describe 'monetize' do
    it 'monetizes cost' do
      occurrence = create(:camp_occurrence, cost_cents: 200000)
      expect(occurrence.cost.cents).to eq(200000)
      expect(occurrence.cost.currency).to eq(Money::Currency.new('USD'))
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      occurrence = build(:camp_occurrence)
      expect(occurrence).to be_valid
    end

    it 'creates occurrence with courses using trait' do
      occurrence = create(:camp_occurrence, :with_courses)
      expect(occurrence.courses.count).to eq(5)
    end

    it 'creates occurrence with activities using trait' do
      occurrence = create(:camp_occurrence, :with_activities)
      expect(occurrence.activities.count).to eq(3)
    end

    it 'creates inactive occurrence using trait' do
      occurrence = create(:camp_occurrence, :inactive)
      expect(occurrence.active).to be false
    end
  end

  describe 'scopes' do
    let(:camp_config) { create(:camp_configuration, :active) }
    let!(:active_occurrence) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let!(:inactive_occurrence) { create(:camp_occurrence, camp_configuration: camp_config, active: false) }

    describe '.active' do
      it 'returns only active occurrences' do
        expect(CampOccurrence.active).to include(active_occurrence)
        expect(CampOccurrence.active).not_to include(inactive_occurrence)
      end
    end

    describe '.no_any_session' do
      it 'excludes occurrences with "Any" in description' do
        any_session = create(:camp_occurrence, description: 'Any Session', camp_configuration: camp_config)
        expect(CampOccurrence.no_any_session).not_to include(any_session)
        expect(CampOccurrence.no_any_session).to include(active_occurrence)
      end
    end
  end

  describe '#display_name' do
    let(:occurrence) { build(:camp_occurrence, description: 'Session 1') }

    it 'returns the description as display name' do
      expect(occurrence.display_name).to eq('Session 1')
    end
  end

  describe '#description_with_month_and_day' do
    let(:occurrence) do
      build(:camp_occurrence,
        description: 'Session 1',
        begin_date: Date.new(2025, 7, 1),
        end_date: Date.new(2025, 7, 8)
      )
    end

    it 'returns description with date range' do
      expected = 'Session 1: July 1 - July 8'
      expect(occurrence.description_with_month_and_day).to eq(expected)
    end
  end

  it_behaves_like 'a model with timestamps'
end
