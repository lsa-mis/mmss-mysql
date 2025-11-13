# frozen_string_literal: true

# == Schema Information
#
# Table name: recommendations
#
#  id                       :bigint           not null, primary key
#  enrollment_id            :bigint           not null
#  email                    :string(255)      not null
#  lastname                 :string(255)      not null
#  firstname                :string(255)      not null
#  organization             :string(255)
#  address1                 :string(255)
#  address2                 :string(255)
#  city                     :string(255)
#  state                    :string(255)
#  state_non_us             :string(255)
#  postalcode               :string(255)
#  country                  :string(255)
#  phone_number             :string(255)
#  best_contact_time        :string(255)
#  submitted_recommendation :string(255)
#  date_submitted           :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_recommendations_on_enrollment_id  (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (enrollment_id => enrollments.id)
#
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
