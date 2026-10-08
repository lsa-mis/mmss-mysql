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
#  upload_token             :string(255)
#  upload_token_expires_at  :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_recommendations_on_enrollment_id  (enrollment_id)
#  index_recommendations_on_upload_token   (upload_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (enrollment_id => enrollments.id)
#
require 'rails_helper'

RSpec.describe Recommendation, type: :model do
  include ActiveSupport::Testing::TimeHelpers

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

  describe 'upload token' do
    let(:recommendation) { create(:recommendation) }

    it 'issues a random token and a 60-day expiry on create' do
      expect(recommendation.upload_token).to match(/\A[1-9A-HJ-NP-Za-km-z]{24}\z/)
      expect(recommendation.upload_token_expires_at).to be_within(1.minute).of(Recommendation::UPLOAD_TOKEN_TTL.from_now)
      expect(recommendation).to be_upload_link_active
      expect(create(:recommendation).upload_token).not_to eq(recommendation.upload_token)
    end

    it 'is not derived from the id' do
      expect(recommendation.upload_token).not_to include(recommendation.id.to_s)
    end

    it 'enforces uniqueness at the database level' do
      other = build(:recommendation, upload_token: recommendation.upload_token)
      expect { other.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    describe '.find_by_upload_token' do
      it 'resolves a known token' do
        expect(Recommendation.find_by_upload_token(recommendation.upload_token)).to eq(recommendation)
      end

      it 'never matches a blank token, even when recommendations with a NULL token exist' do
        recommendation.invalidate_upload_token!

        expect(Recommendation.find_by_upload_token(nil)).to be_nil
        expect(Recommendation.find_by_upload_token('')).to be_nil
        expect(Recommendation.find_by_upload_token([''])).to be_nil
      end

      it 'returns nil for an unknown token' do
        expect(Recommendation.find_by_upload_token('nope')).to be_nil
      end
    end

    describe '#upload_token_expired?' do
      it 'is false before the expiry and true after it' do
        expect(recommendation).not_to be_upload_token_expired

        travel_to(Recommendation::UPLOAD_TOKEN_TTL.from_now + 1.day) do
          expect(recommendation).to be_upload_token_expired
          expect(recommendation).not_to be_upload_link_active
        end
      end

      it 'treats a missing expiry as expired' do
        recommendation.update_columns(upload_token_expires_at: nil)
        expect(recommendation).to be_upload_token_expired
      end
    end

    describe '#issue_upload_token!' do
      it 'replaces the token and restarts the expiry window' do
        recommendation.update_columns(upload_token_expires_at: 1.day.ago)
        old_token = recommendation.upload_token

        recommendation.issue_upload_token!

        expect(recommendation.reload.upload_token).not_to eq(old_token)
        expect(recommendation.upload_token_expires_at).to be_within(1.minute).of(Recommendation::UPLOAD_TOKEN_TTL.from_now)
        expect(Recommendation.find_by_upload_token(old_token)).to be_nil
      end
    end

    describe '#invalidate_upload_token!' do
      it 'clears the token and expiry' do
        recommendation.invalidate_upload_token!

        expect(recommendation.reload.upload_token).to be_nil
        expect(recommendation.upload_token_expires_at).to be_nil
        expect(recommendation).not_to be_upload_link_active
      end
    end

    it 'is cleared once a letter is received' do
      token = recommendation.upload_token
      create(:recupload, recommendation: recommendation)

      expect(recommendation.reload.upload_token).to be_nil
      expect(Recommendation.find_by_upload_token(token)).to be_nil
      expect(recommendation).not_to be_upload_link_active
    end
  end

  it_behaves_like 'a model with timestamps'
end
