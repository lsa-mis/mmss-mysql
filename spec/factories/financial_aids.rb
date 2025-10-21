FactoryBot.define do
  factory :financial_aid do
    association :enrollment

    amount_cents { rand(50000..200000) }
    source { ['Scholarship', 'Grant', 'Need-based Aid', 'Merit Award'].sample }
    note { Faker::Lorem.sentence }
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
