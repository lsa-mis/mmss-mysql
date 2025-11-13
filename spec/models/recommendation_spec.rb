# frozen_string_literal: true

# == Schema Information
#
# Table name: recommendations
#
#  id                       :bigint           not null, primary key
#  enrollment_id            :bigint           not null
#  email                    :string(255)      not null
#  lastname                 :string(255)      not null
#  firstname                :string(255)      not null
#  organization             :string(255)
#  address1                 :string(255)
#  address2                 :string(255)
#  city                     :string(255)
#  state                    :string(255)
#  state_non_us             :string(255)
#  postalcode               :string(255)
#  country                  :string(255)
#  phone_number             :string(255)
#  best_contact_time        :string(255)
#  submitted_recommendation :string(255)
#  date_submitted           :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_recommendations_on_enrollment_id  (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (enrollment_id => enrollments.id)
#
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
      expect(recommendation.submitted_recommendation).to eq('1')
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
