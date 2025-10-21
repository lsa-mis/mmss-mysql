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
