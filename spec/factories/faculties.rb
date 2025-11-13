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
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    sequence(:email) { |n| "faculty#{n}@university.edu" }
    sequence(:uniqname) { |n| "prof#{n}" }
    title { ['Professor', 'Associate Professor', 'Assistant Professor', 'Lecturer'].sample }
    department { Faker::Educator.subject }
    phone { Faker::PhoneNumber.phone_number }

    trait :professor do
      title { 'Professor' }
    end

    trait :associate_professor do
      title { 'Associate Professor' }
    end

    trait :assistant_professor do
      title { 'Assistant Professor' }
    end
  end
end
