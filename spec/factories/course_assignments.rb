# frozen_string_literal: true

FactoryBot.define do
  factory :course_assignment do
    association :enrollment
    association :course

    wait_list { false }

    trait :waitlisted do
      wait_list { true }
    end

    trait :active do
      wait_list { false }
    end
  end
end
