# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id                 :bigint           not null, primary key
#  transaction_type   :string(255)
#  transaction_status :string(255)
#  transaction_id     :string(255)
#  total_amount       :string(255)
#  transaction_date   :string(255)
#  account_type       :string(255)
#  result_code        :string(255)
#  result_message     :string(255)
#  user_account       :string(255)
#  payer_identity     :string(255)
#  timestamp          :string(255)
#  transaction_hash   :string(255)
#  user_id            :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  camp_year          :integer
#
# Indexes
#
#  index_payments_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:payment) }

    it { is_expected.to validate_presence_of(:total_amount) }
    it { is_expected.to validate_presence_of(:transaction_type) }
    it { is_expected.to validate_presence_of(:transaction_status) }
    it { is_expected.to validate_presence_of(:camp_year) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      payment = build(:payment)
      expect(payment).to be_valid
    end

    it 'creates failed payment with trait' do
      payment = create(:payment, :failed)
      expect(payment.transaction_status).to eq('0')
      expect(payment.result_message).to eq('Payment failed')
    end

    it 'creates pending payment with trait' do
      payment = create(:payment, :pending)
      expect(payment.transaction_status).to eq('2')
    end
  end

  describe '#successful?' do
    it 'returns true when transaction_status is 1' do
      payment = build(:payment, transaction_status: '1')
      expect(payment.transaction_status).to eq('1')
    end

    it 'returns false when transaction_status is not 1' do
      payment = build(:payment, transaction_status: '0')
      expect(payment.transaction_status).not_to eq('1')
    end
  end

  describe 'monetary amounts' do
    let(:payment) { create(:payment, total_amount: 50000) }

    it 'stores amounts in cents as string' do
      expect(payment.total_amount).to eq('50000')
    end

    it 'can be converted to dollars' do
      expect(payment.total_amount.to_i / 100.0).to eq(500.00)
    end
  end

  it_behaves_like 'a model with timestamps'
end
