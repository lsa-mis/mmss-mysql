# This factory is for session model if it exists
# Note: Based on the project structure, sessions might refer to camp_occurrences
# Keeping this file for compatibility with existing test references

FactoryBot.define do
  factory :session, class: 'CampOccurrence' do
    association :camp_configuration

    sequence(:description) { |n| "Session #{n}" }
    begin_date { Faker::Date.between(from: 6.months.from_now, to: 8.months.from_now) }
    end_date { begin_date + 7.days }
    cost_cents { 200_000 }
    active { true }
  end
end
