# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_one(:applicant_detail).dependent(:destroy) }
    it { is_expected.to have_many(:enrollments).dependent(:destroy) }
    it { is_expected.to have_many(:payments).dependent(:destroy) }
    it { is_expected.to have_many(:feedbacks).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to allow_value('valid@email.com').for(:email) }
    it { is_expected.not_to allow_value('invalid_email').for(:email) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'creates a user with sign ins using trait' do
      user = create(:user, :with_sign_ins)
      expect(user.sign_in_count).to be > 0
      expect(user.current_sign_in_at).to be_present
    end
  end

  describe '#display_name' do
    let(:user) { create(:user) }

    it 'returns the email as display name' do
      expect(user.display_name).to eq(user.email)
    end
  end

  describe 'devise configuration' do
    it 'is configured for database_authenticatable' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'is configured for registerable' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'is configured for recoverable' do
      expect(User.devise_modules).to include(:recoverable)
    end

    it 'is configured for rememberable' do
      expect(User.devise_modules).to include(:rememberable)
    end

    it 'is configured for validatable' do
      expect(User.devise_modules).to include(:validatable)
    end

    it 'is configured for trackable' do
      expect(User.devise_modules).to include(:trackable)
    end

    it 'is configured for timeoutable' do
      expect(User.devise_modules).to include(:timeoutable)
    end
  end

  describe '.ransackable_attributes' do
    it 'returns searchable attributes' do
      expect(User.ransackable_attributes).to include('email')
    end
  end

  it_behaves_like 'a model with timestamps'
end
