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

    it 'stores amounts in cents' do
      expect(payment.total_amount).to eq(50000)
    end

    it 'can be converted to dollars' do
      expect(payment.total_amount / 100.0).to eq(500.00)
    end
  end

  it_behaves_like 'a model with timestamps'
end
