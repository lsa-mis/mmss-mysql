# frozen_string_literal: true

# == Schema Information
#
# Table name: admins
#
#  id                     :bigint           not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string(255)
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#
# Indexes
#
#  index_admins_on_email                 (email) UNIQUE
#  index_admins_on_reset_password_token  (reset_password_token) UNIQUE
#
require 'rails_helper'

RSpec.describe Admin, type: :model do
  describe 'validations' do
    subject { build(:admin) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to allow_value('valid@email.com').for(:email) }
    it { is_expected.not_to allow_value('invalid_email').for(:email) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      admin = build(:admin)
      expect(admin).to be_valid
    end

    it 'creates locked admin with trait' do
      admin = create(:admin, :locked)
      expect(admin.locked_at).to be_present
      expect(admin.failed_attempts).to eq(5)
    end

    it 'creates admin with sign ins using trait' do
      admin = create(:admin, :with_sign_ins)
      expect(admin.sign_in_count).to be > 0
    end
  end

  describe 'devise configuration' do
    it 'is configured for database_authenticatable' do
      expect(Admin.devise_modules).to include(:database_authenticatable)
    end

    it 'is configured for trackable' do
      expect(Admin.devise_modules).to include(:trackable)
    end

    it 'is configured for lockable' do
      expect(Admin.devise_modules).to include(:lockable)
    end
  end

  it_behaves_like 'a model with timestamps'
end
