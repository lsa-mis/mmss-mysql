FactoryBot.define do
  factory :camp_occurrence do
    association :camp_configuration

    sequence(:description) { |n| "Session #{n}" }
    begin_date { Faker::Date.between(from: 6.months.from_now, to: 8.months.from_now) }
    end_date { begin_date + 7.days }
    cost_cents { 200_000 }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_courses do
      after(:create) do |camp_occurrence|
        create_list(:course, 5, camp_occurrence: camp_occurrence)
      end
    end

    trait :with_activities do
      after(:create) do |camp_occurrence|
        create_list(:activity, 3, camp_occurrence: camp_occurrence)
      end
    end

    trait :summer do
      begin_date { Date.new(camp_configuration.camp_year, 7, 1) }
      end_date { Date.new(camp_configuration.camp_year, 7, 8) }
    end

    trait :fall do
      begin_date { Date.new(camp_configuration.camp_year, 9, 14) }
      end_date { Date.new(camp_configuration.camp_year, 9, 21) }
    end
  end
end
