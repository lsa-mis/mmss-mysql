# frozen_string_literal: true

FactoryBot.define do
  factory :recommendation do
    association :enrollment

    sequence(:email) { |n| "recommender#{n}@example.com" }
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    organization { Faker::Educator.university }
    address1 { Faker::Address.street_address }
    address2 { [nil, Faker::Address.secondary_address].sample }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    state_non_us { nil }
    postalcode { Faker::Address.zip_code }
    country { 'US' }
    phone_number { Faker::PhoneNumber.phone_number }
    best_contact_time { ['Morning', 'Afternoon', 'Evening'].sample }
    submitted_recommendation { false }
    date_submitted { nil }

    trait :submitted do
      submitted_recommendation { true }
      date_submitted { Faker::Date.backward(days: 30) }
    end

    trait :international do
      country { Faker::Address.country_code }
      state { nil }
      state_non_us { Faker::Address.state }
    end

    trait :with_upload do
      after(:create) do |recommendation|
        create(:recupload, recommendation: recommendation)
      end
    end
  end
end
