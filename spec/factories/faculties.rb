# frozen_string_literal: true

# == Schema Information
#
# Table name: faculties
#
#  id                     :bigint           not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_faculties_on_email                 (email) UNIQUE
#  index_faculties_on_reset_password_token  (reset_password_token) UNIQUE
#
FactoryBot.define do
  factory :faculty do
    sequence(:email) { |n| "faculty#{n}@university.edu" }
    password { "FacultyPassword123!" }
    password_confirmation { "FacultyPassword123!" }

    trait :with_sign_ins do
      sign_in_count { rand(1..10) }
      current_sign_in_at { Faker::Time.between(from: 1.day.ago, to: Time.current) }
      last_sign_in_at { Faker::Time.between(from: 7.days.ago, to: 2.days.ago) }
      current_sign_in_ip { Faker::Internet.ip_v4_address }
      last_sign_in_ip { Faker::Internet.ip_v4_address }
    end
  end
end
