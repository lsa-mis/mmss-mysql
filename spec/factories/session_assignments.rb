FactoryBot.define do
  factory :session_assignment do
    association :enrollment
    association :camp_occurrence

    offer_status { nil }

    trait :accepted do
      offer_status { 'accepted' }
    end

    trait :declined do
      offer_status { 'declined' }
    end

    trait :pending do
      offer_status { nil }
    end
  end
end
