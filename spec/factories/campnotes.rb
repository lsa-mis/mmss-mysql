# frozen_string_literal: true

FactoryBot.define do
  factory :campnote do
    note { Faker::Lorem.paragraph }
    notetype { 'general' }
    opendate { 1.week.from_now }
    closedate { 2.weeks.from_now }
  end
end
