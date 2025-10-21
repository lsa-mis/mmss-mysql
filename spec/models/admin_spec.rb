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
