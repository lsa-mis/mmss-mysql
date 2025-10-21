# frozen_string_literal: true

FactoryBot.define do
  factory :enrollment_activity do
    association :enrollment
    association :activity
  end
end
