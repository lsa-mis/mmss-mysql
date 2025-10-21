# == Schema Information
#
# Table name: users
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
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "SecurePassword123!" }
    password_confirmation { "SecurePassword123!" }

    trait :with_sign_ins do
      sign_in_count { rand(1..10) }
      current_sign_in_at { Faker::Time.between(from: 1.day.ago, to: Time.current) }
      last_sign_in_at { Faker::Time.between(from: 7.days.ago, to: 2.days.ago) }
      current_sign_in_ip { Faker::Internet.ip_v4_address }
      last_sign_in_ip { Faker::Internet.ip_v4_address }
    end

    trait :with_applicant_detail do
      after(:create) do |user|
        create(:applicant_detail, user: user)
      end
    end

    trait :with_enrollment do
      after(:create) do |user|
        create(:applicant_detail, user: user)
        # Note: Enrollment requires additional setup (sessions, courses)
        # Use create_complete_enrollment helper instead
      end
    end
  end
end
