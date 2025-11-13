# frozen_string_literal: true

# == Schema Information
#
# Table name: financial_aids
#
#  id                    :bigint           not null, primary key
#  enrollment_id         :bigint           not null
#  amount_cents          :integer          default(0)
#  source                :string(255)
#  note                  :text(65535)
#  status                :string(255)      default("pending")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  payments_deadline     :date
#  adjusted_gross_income :integer
#
# Indexes
#
#  index_financial_aids_on_enrollment_id  (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (enrollment_id => enrollments.id)
#
require 'rails_helper'

RSpec.describe FinancialAid, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:enrollment) }
  end

  describe 'validations' do
    subject { build(:financial_aid) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:adjusted_gross_income) }
    it { is_expected.to validate_numericality_of(:adjusted_gross_income).is_greater_than_or_equal_to(0) }

    describe 'source validation' do
      context 'when status is awarded and amount is assigned' do
        it 'requires source to be present' do
          aid = build(:financial_aid, status: 'awarded', amount_cents: 100000, source: nil)
          expect(aid).not_to be_valid
          expect(aid.errors[:source]).to include("is required when status is awarded and an amount is assigned")
        end

        it 'is valid when source is present' do
          aid = build(:financial_aid, status: 'awarded', amount_cents: 100000, source: 'Scholarship')
          expect(aid).to be_valid
        end
      end

      context 'when status is not awarded' do
        it 'does not require source' do
          aid = build(:financial_aid, status: 'pending', source: nil)
          expect(aid).to be_valid
        end
      end

      context 'when status is awarded but amount is zero' do
        it 'does not require source' do
          aid = build(:financial_aid, status: 'awarded', amount_cents: 0, source: nil)
          expect(aid).to be_valid
        end
      end
    end
  end

  describe 'monetize' do
    it 'monetizes amount' do
      aid = create(:financial_aid, amount_cents: 100000)
      expect(aid.amount.cents).to eq(100000)
      expect(aid.amount.currency).to eq(Money::Currency.new('USD'))
    end
  end

  describe 'attachments' do
    it { is_expected.to have_one_attached(:taxform) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      aid = build(:financial_aid)
      expect(aid).to be_valid
    end

    it 'creates approved aid with trait' do
      aid = create(:financial_aid, :approved)
      expect(aid.status).to eq('approved')
    end

    it 'creates full scholarship with trait' do
      aid = create(:financial_aid, :full_scholarship)
      expect(aid.amount_cents).to eq(200000)
      expect(aid.status).to eq('approved')
    end

    it 'creates aid with taxform using trait' do
      aid = create(:financial_aid, :with_taxform)
      expect(aid.taxform).to be_attached
    end
  end

  describe 'scopes' do
    let(:camp_config) do
      CampConfiguration.find_or_create_by!(camp_year: Date.current.year) do |cc|
        cc.application_open = Date.current - 30.days
        cc.application_close = Date.current + 90.days
        cc.priority = Date.current + 30.days
        cc.application_materials_due = Date.current + 60.days
        cc.camper_acceptance_due = Date.current + 75.days
        cc.application_fee_cents = 10_000
        cc.active = true
        cc.offer_letter = 'Default offer letter'
        cc.reject_letter = 'Default reject letter'
        cc.waitlist_letter = 'Default waitlist letter'
      end
    end
    let(:enrollment) { create(:enrollment, campyear: Date.current.year) }
    let!(:current_aid) { create(:financial_aid, enrollment: enrollment) }

    let(:old_enrollment) { create(:enrollment, campyear: Date.current.year - 1) }
    let!(:old_aid) { create(:financial_aid, enrollment: old_enrollment) }

    before do
      # Ensure the current year's camp configuration is active
      CampConfiguration.update_all(active: false)
      camp_config.update!(active: true)
      allow(CampConfiguration).to receive(:active_camp_year).and_return(camp_config.camp_year)
    end

    describe '.current_camp_requests' do
      it 'returns financial aid for current camp year' do
        expect(FinancialAid.current_camp_requests).to include(current_aid)
        expect(FinancialAid.current_camp_requests).not_to include(old_aid)
      end
    end
  end

  it_behaves_like 'a model with timestamps'
end
