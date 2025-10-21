# frozen_string_literal: true

FactoryBot.define do
  factory :activity do
    association :camp_occurrence

    sequence(:description) { |n| "Activity #{n}" }
    cost_cents { [0, 5000, 10000, 15000].sample }
    date_occurs { camp_occurrence&.begin_date || Faker::Date.forward(days: 30) }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :free do
      cost_cents { 0 }
    end

    trait :residential do
      description { 'Residential Stay' }
      cost_cents { 50000 }
    end

    trait :past do
      date_occurs { Faker::Date.backward(days: 30) }
    end

    trait :future do
      date_occurs { Faker::Date.forward(days: 30) }
    end
  end
end
