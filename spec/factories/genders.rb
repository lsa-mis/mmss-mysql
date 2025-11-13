# frozen_string_literal: true

# == Schema Information
#
# Table name: genders
#
#  id          :bigint           not null, primary key
#  name        :string(255)      not null
#  description :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :gender do
    sequence(:name) { |n| "Gender#{n}" }
    description { "#{name} description" }

    trait :female do
      name { 'Female' }
      description { 'Female' }
    end

    trait :male do
      name { 'Male' }
      description { 'Male' }
    end

    trait :non_binary do
      name { 'Non-binary' }
      description { 'Non-binary' }
    end
  end
end
