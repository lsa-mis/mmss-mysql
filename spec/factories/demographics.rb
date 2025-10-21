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
