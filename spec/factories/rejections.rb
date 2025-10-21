FactoryBot.define do
  factory :rejection do
    association :enrollment

    reason { Faker::Lorem.paragraph }

    trait :incomplete_application do
      reason { 'Application was incomplete' }
    end

    trait :does_not_meet_requirements do
      reason { 'Does not meet program requirements' }
    end
  end
end
