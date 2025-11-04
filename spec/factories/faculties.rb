# frozen_string_literal: true

FactoryBot.define do
  factory :faculty do
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    sequence(:email) { |n| "faculty#{n}@university.edu" }
    sequence(:uniqname) { |n| "prof#{n}" }
    title { ['Professor', 'Associate Professor', 'Assistant Professor', 'Lecturer'].sample }
    department { Faker::Educator.subject }
    phone { Faker::PhoneNumber.phone_number }

    trait :professor do
      title { 'Professor' }
    end

    trait :associate_professor do
      title { 'Associate Professor' }
    end

    trait :assistant_professor do
      title { 'Assistant Professor' }
    end
  end
end
