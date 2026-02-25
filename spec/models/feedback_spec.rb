# frozen_string_literal: true

require 'rails_helper'

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

  describe 'ransackable' do
    it 'returns ransackable associations' do
      expect(described_class.ransackable_associations(nil)).to eq(['user'])
    end

    it 'returns ransackable attributes' do
      expect(described_class.ransackable_attributes(nil)).to include(
        'created_at', 'genre', 'id', 'message', 'updated_at', 'user_id'
      )
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
