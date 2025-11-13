# frozen_string_literal: true

# == Schema Information
#
# Table name: travels
#
#  id                :bigint           not null, primary key
#  enrollment_id     :bigint           not null
#  arrival_transport :string(255)
#  arrival_carrier   :string(255)
#  arrival_route_num :string(255)
#  note              :text(65535)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  arrival_date      :date
#  arrival_time      :time
#  depart_transport  :string(255)
#  depart_route_num  :string(255)
#  depart_date       :date
#  depart_time       :time
#  depart_carrier    :string(255)
#  arrival_session   :string(255)
#  depart_session    :string(255)
#
# Indexes
#
#  index_travels_on_enrollment_id  (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (enrollment_id => enrollments.id)
#
FactoryBot.define do
  factory :travel do
    association :enrollment

    arrival_session { 'Session 1' }
    depart_session { 'Session 1' }

    arrival_transport { ['Flight', 'Train', 'Bus', 'Car', 'Other'].sample }
    arrival_carrier { Faker::Company.name }
    sequence(:arrival_route_num) { |n| "AR#{n}" }
    arrival_date { Faker::Date.forward(days: 30) }
    arrival_time { Faker::Time.forward(days: 30) }

    depart_transport { ['Flight', 'Train', 'Bus', 'Car', 'Other'].sample }
    depart_carrier { Faker::Company.name }
    sequence(:depart_route_num) { |n| "DR#{n}" }
    depart_date { arrival_date + 7.days }
    depart_time { Faker::Time.forward(days: 37) }

    note { Faker::Lorem.sentence }

    trait :by_flight do
      arrival_transport { 'Flight' }
      depart_transport { 'Flight' }
      arrival_carrier { ['Delta', 'United', 'American', 'Southwest'].sample }
      depart_carrier { ['Delta', 'United', 'American', 'Southwest'].sample }
    end

    trait :by_car do
      arrival_transport { 'Car' }
      depart_transport { 'Car' }
      arrival_carrier { 'N/A' }
      depart_carrier { 'N/A' }
    end
  end
end
