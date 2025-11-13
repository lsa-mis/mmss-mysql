# frozen_string_literal: true

# == Schema Information
#
# Table name: demographics
#
#  id          :bigint           not null, primary key
#  name        :string(255)      not null
#  description :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  protected   :boolean          default(FALSE)
#
FactoryBot.define do
  factory :demographic do
    sequence(:name) { |n| "Demographic #{n}" }
    description { Faker::Lorem.sentence }
    protected { false }

    trait :protected do
      protected { true }
    end

    trait :other do
      name { 'Other' }
      description { 'Other demographic option' }
      protected { true }
    end
  end
end
