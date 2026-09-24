# frozen_string_literal: true

require 'rails_helper'

# == Schema Information
#
# Table name: feedbacks
#
#  id         :bigint           not null, primary key
#  genre      :string(255)
#  message    :string(255)
#  user_id    :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_feedbacks_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
RSpec.describe Feedback, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'constants' do
    it 'defines MESSAGE_MAX_LENGTH as 255' do
      expect(described_class::MESSAGE_MAX_LENGTH).to eq(255)
    end
  end

  describe 'validations' do
    subject { build(:feedback) }

    it { is_expected.to validate_presence_of(:genre) }
    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.to validate_length_of(:message).is_at_most(255).with_message(/too long/) }
  end

  describe 'valid feedback' do
    it 'is valid with genre, message, and user' do
      feedback = build(:feedback, genre: 'page_error', message: 'Something broke on the page.')
      expect(feedback).to be_valid
    end

    it 'accepts all allowed genre values' do
      %w[page_error layout_issue suggestion].each do |genre|
        feedback = build(:feedback, genre: genre)
        expect(feedback).to be_valid
      end
    end

    it 'is valid with message at exactly 255 characters' do
      feedback = build(:feedback, message: 'x' * 255)
      expect(feedback).to be_valid
    end
  end

  describe 'invalid feedback' do
    it 'is invalid without genre' do
      feedback = build(:feedback, genre: nil)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:genre]).to include("can't be blank")
    end

    it 'is invalid without message' do
      feedback = build(:feedback, message: nil)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:message]).to include("can't be blank")
    end

    it 'is invalid with blank message' do
      feedback = build(:feedback, message: '   ')
      expect(feedback).not_to be_valid
      expect(feedback.errors[:message]).to include("can't be blank")
    end

    it 'is invalid when message exceeds 255 characters' do
      feedback = build(:feedback, message: 'x' * 256)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:message]).to include(match(/too long.*255/))
    end
  end

  describe 'GENRES and #genre_label' do
    it 'lists the three genres offered by the public feedback form' do
      expect(described_class::GENRES.keys).to eq(%w[page_error layout_issue suggestion])
    end

    it 'returns the label for a known genre and the raw value otherwise' do
      expect(build(:feedback, genre: 'page_error').genre_label).to eq('Error on Page')
      expect(build(:feedback, genre: 'something_else').genre_label).to eq('something_else')
    end
  end

  describe 'factory' do
    it 'has a valid default factory' do
      expect(build(:feedback)).to be_valid
    end

    it 'builds with max_message trait' do
      feedback = build(:feedback, :max_message)
      expect(feedback.message.length).to eq(255)
      expect(feedback).to be_valid
    end
  end
end
