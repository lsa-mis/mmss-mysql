# frozen_string_literal: true

FactoryBot.define do
  factory :gender do
    sequence(:name) { |n| "Gender#{n}" }
    description { "#{name} description" }

    trait :female do
      name { 'Female' }
      description { 'Female' }
    end

    trait :male do
      name { 'Male' }
      description { 'Male' }
    end

    trait :non_binary do
      name { 'Non-binary' }
      description { 'Non-binary' }
    end
  end
end
