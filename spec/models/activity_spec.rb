require 'rails_helper'

RSpec.describe Activity, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:camp_occurrence) }
    it { is_expected.to have_many(:enrollment_activities).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:activity) }

    it { is_expected.to validate_presence_of(:description) }
  end

  describe 'monetize' do
    it 'monetizes cost' do
      activity = create(:activity, cost_cents: 5000)
      expect(activity.cost.cents).to eq(5000)
      expect(activity.cost.currency).to eq(Money::Currency.new('USD'))
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      activity = build(:activity)
      expect(activity).to be_valid
    end

    it 'creates inactive activity with trait' do
      activity = create(:activity, :inactive)
      expect(activity.active).to be false
    end

    it 'creates free activity with trait' do
      activity = create(:activity, :free)
      expect(activity.cost_cents).to eq(0)
    end

    it 'creates residential activity with trait' do
      activity = create(:activity, :residential)
      expect(activity.description).to eq('Residential Stay')
    end
  end

  it_behaves_like 'a model with timestamps'
end
