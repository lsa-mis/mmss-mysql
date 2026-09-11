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

    it 'optionally has one payment_request' do
      payment = create(:payment)
      request = create(:payment_request, user: payment.user, payment: payment)

      expect(payment.payment_request).to eq(request)
    end
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

  describe '#total_amount_dollars' do
    it 'converts stored cents to a dollar float for admin display' do
      payment = build(:payment, total_amount: '12345')
      expect(payment.total_amount_dollars).to eq(123.45)
    end

    it 'returns nil when total_amount is blank' do
      payment = build(:payment, total_amount: nil)
      expect(payment.total_amount_dollars).to be_nil
    end

    it 'stores dollars as rounded cents when assigned' do
      payment = build(:payment)
      payment.total_amount_dollars = '99.999'
      expect(payment.total_amount).to eq('10000')
    end

    it 'clears total_amount when assigned a blank dollar value' do
      payment = build(:payment, total_amount: '5000')
      payment.total_amount_dollars = '  '
      expect(payment.total_amount).to be_nil
    end
  end

  it_behaves_like 'a model with timestamps'
end
