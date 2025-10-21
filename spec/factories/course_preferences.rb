# frozen_string_literal: true

FactoryBot.define do
  factory :course_preference do
    association :enrollment
    association :course

    ranking { rand(1..10) }
  end
end
