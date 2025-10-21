FactoryBot.define do
  factory :feedback do
    association :user
    association :camp_configuration

    communication_rating { rand(1..5) }
    food_rating { rand(1..5) }
    housing_rating { rand(1..5) }
    courses_rating { rand(1..5) }
    activities_rating { rand(1..5) }
    overall_rating { rand(1..5) }
    what_liked { Faker::Lorem.paragraph }
    what_to_improve { Faker::Lorem.paragraph }
    comments { Faker::Lorem.paragraph }

    trait :excellent do
      communication_rating { 5 }
      food_rating { 5 }
      housing_rating { 5 }
      courses_rating { 5 }
      activities_rating { 5 }
      overall_rating { 5 }
    end

    trait :poor do
      communication_rating { 2 }
      food_rating { 2 }
      housing_rating { 2 }
      courses_rating { 2 }
      activities_rating { 2 }
      overall_rating { 2 }
    end
  end
end
