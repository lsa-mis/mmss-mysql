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
FactoryBot.define do
  factory :financial_aid do
    association :enrollment

    amount_cents { rand(50000..200000) }
    source { ['Scholarship', 'Grant', 'Need-based Aid', 'Merit Award'].sample }
    note { Faker::Lorem.sentence }
    adjusted_gross_income { rand(20000..150000) }
    status { 'pending' }
    payments_deadline { 30.days.from_now }

    trait :pending do
      status { 'pending' }
    end

    trait :approved do
      status { 'approved' }
    end

    trait :denied do
      status { 'denied' }
    end

    trait :disbursed do
      status { 'disbursed' }
    end

    trait :full_scholarship do
      amount_cents { 200000 }
      source { 'Full Scholarship' }
      status { 'approved' }
    end

    trait :partial_aid do
      amount_cents { rand(25000..75000) }
      source { 'Partial Aid' }
    end

    trait :with_taxform do
      after(:create) do |financial_aid|
        link_to_default_pdf = "#{Rails.root}/spec/files/test.pdf"
        financial_aid.taxform.attach(
          io: File.open(link_to_default_pdf),
          filename: 'taxform.pdf',
          content_type: 'application/pdf'
        )
      end
    end
  end
end
