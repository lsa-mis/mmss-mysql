# frozen_string_literal: true

FactoryBot.define do
  factory :session_activity do
    association :enrollment
    association :camp_occurrence
  end
end
