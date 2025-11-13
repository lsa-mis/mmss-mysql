# frozen_string_literal: true

# == Schema Information
#
# Table name: camp_occurrences
#
#  id                    :bigint           not null, primary key
#  camp_configuration_id :bigint           not null
#  description           :string(255)      not null
#  begin_date            :date             not null
#  end_date              :date             not null
#  active                :boolean          default(FALSE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  cost_cents            :integer
#
# Indexes
#
#  index_camp_occurrences_on_camp_configuration_id  (camp_configuration_id)
#
# Foreign Keys
#
#  fk_rails_...  (camp_configuration_id => camp_configurations.id)
#
FactoryBot.define do
  factory :camp_occurrence do
    association :camp_configuration

    sequence(:description) { |n| "Session #{n}" }
    begin_date { Faker::Date.between(from: 6.months.from_now, to: 8.months.from_now) }
    end_date { begin_date + 7.days }
    cost_cents { 200_000 }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_courses do
      after(:create) do |camp_occurrence|
        create_list(:course, 5, camp_occurrence: camp_occurrence)
      end
    end

    trait :with_activities do
      after(:create) do |camp_occurrence|
        create_list(:activity, 3, camp_occurrence: camp_occurrence)
      end
    end

    trait :summer do
      begin_date { Date.new(camp_configuration.camp_year, 7, 1) }
      end_date { Date.new(camp_configuration.camp_year, 7, 8) }
    end

    trait :fall do
      begin_date { Date.new(camp_configuration.camp_year, 9, 14) }
      end_date { Date.new(camp_configuration.camp_year, 9, 21) }
    end
  end
end
