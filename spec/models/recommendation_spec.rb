require 'rails_helper'

RSpec.describe Recommendation, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:enrollment) }
    it { is_expected.to have_one(:recupload).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:recommendation) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:firstname) }
    it { is_expected.to validate_presence_of(:lastname) }
    it { is_expected.to allow_value('valid@email.com').for(:email) }
    it { is_expected.not_to allow_value('invalid_email').for(:email) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      recommendation = build(:recommendation)
      expect(recommendation).to be_valid
    end

    it 'creates submitted recommendation with trait' do
      recommendation = create(:recommendation, :submitted)
      expect(recommendation.submitted_recommendation).to be true
      expect(recommendation.date_submitted).to be_present
    end

    it 'creates international recommendation with trait' do
      recommendation = create(:recommendation, :international)
      expect(recommendation.country).not_to eq('US')
      expect(recommendation.state_non_us).to be_present
    end

    it 'creates recommendation with upload using trait' do
      recommendation = create(:recommendation, :with_upload)
      expect(recommendation.recupload).to be_present
    end
  end

  describe '#full_name' do
    let(:recommendation) { build(:recommendation, firstname: 'Jane', lastname: 'Smith') }

    it 'returns the full name' do
      expect(recommendation.firstname).to eq('Jane')
      expect(recommendation.lastname).to eq('Smith')
    end
  end

  it_behaves_like 'a model with timestamps'
end
