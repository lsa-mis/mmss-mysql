# frozen_string_literal: true

# == Schema Information
#
# Table name: admins
#
#  id                     :bigint           not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string(255)
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#
# Indexes
#
#  index_admins_on_email                 (email) UNIQUE
#  index_admins_on_reset_password_token  (reset_password_token) UNIQUE
#
FactoryBot.define do
  factory :admin do
    sequence(:email) { |n| "admin#{n}@example.com" }
    password { "AdminPassword123!" }
    password_confirmation { "AdminPassword123!" }

    trait :locked do
      locked_at { 1.hour.ago }
      failed_attempts { 5 }
    end

    trait :with_sign_ins do
      sign_in_count { rand(1..100) }
      current_sign_in_at { Faker::Time.between(from: 1.day.ago, to: Time.current) }
      last_sign_in_at { Faker::Time.between(from: 7.days.ago, to: 2.days.ago) }
      current_sign_in_ip { Faker::Internet.ip_v4_address }
      last_sign_in_ip { Faker::Internet.ip_v4_address }
    end
  end
end
