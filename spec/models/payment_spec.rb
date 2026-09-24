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
    it { is_expected.to have_one(:payment_request).dependent(:restrict_with_error) }
  end

  describe '#destroy' do
    let(:user) { create(:user) }

    it 'refuses to destroy a payment matched to a Nelnet payment request' do
      payment = create(:payment, user: user, transaction_status: '2')
      create(:payment_request, user: user, payment: payment)

      expect(payment.destroy).to be(false)
      expect(payment.errors[:base]).to be_present
      expect(Payment.exists?(payment.id)).to be(true)
    end

    it 'destroys an unmatched payment' do
      payment = create(:payment, user: user, transaction_status: '2')

      expect(payment.destroy).to be_truthy
      expect(Payment.exists?(payment.id)).to be(false)
    end
  end

  describe 'validations' do
    subject { build(:payment) }

    it { is_expected.to validate_presence_of(:total_amount) }
    it { is_expected.to validate_presence_of(:transaction_type) }
    it { is_expected.to validate_presence_of(:transaction_status) }
    it { is_expected.to validate_presence_of(:camp_year) }

    it 'requires total_amount to be a whole number of cents' do
      %w[-100 10.5 abc].each do |bad|
        payment = build(:payment, total_amount: bad)
        expect(payment).not_to be_valid, "#{bad.inspect} was accepted"
        expect(payment.errors[:total_amount]).to include('must be a whole number of cents')
      end
      expect(build(:payment, total_amount: '0')).to be_valid
    end
  end

  describe '#total_amount_dollars=' do
    it 'stores whole cents for plain, formatted and two-decimal input' do
      expect(build(:payment, total_amount_dollars: '150').total_amount).to eq('15000')
      expect(build(:payment, total_amount_dollars: '150.25').total_amount).to eq('15025')
      expect(build(:payment, total_amount_dollars: '$1,500.5').total_amount).to eq('150050')
      expect(build(:payment, total_amount_dollars: ' 7 ').total_amount).to eq('700')
    end

    it 'treats blank input as a missing amount' do
      payment = build(:payment, total_amount_dollars: '')
      expect(payment).not_to be_valid
      expect(payment.errors[:total_amount]).to include("can't be blank")
      expect(payment.errors[:total_amount_dollars]).to be_empty
    end

    it 'refuses negative, non-numeric, non-finite and over-precise input without coercing it' do
      ['-5', 'abc', 'Infinity', '-Infinity', 'NaN', '1e3', '12.345', '0x10'].each do |bad|
        payment = build(:payment, total_amount: '25050', total_amount_dollars: bad)
        expect(payment.total_amount).to eq('25050'), "#{bad.inspect} overwrote the amount"
        expect(payment).not_to be_valid, "#{bad.inspect} was accepted"
        expect(payment.errors[:total_amount_dollars].first).to include('non-negative dollar amount')
        expect(payment.total_amount_dollars).to eq(bad)
      end
    end

    it 'reads back the stored amount in dollars' do
      expect(build(:payment, total_amount: '25050').total_amount_dollars).to eq(250.5)
      expect(build(:payment, total_amount: nil).total_amount_dollars).to be_nil
    end
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
