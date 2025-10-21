FactoryBot.define do
  factory :campnote do
    association :camp_configuration

    note { Faker::Lorem.paragraph }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
