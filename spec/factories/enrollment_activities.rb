FactoryBot.define do
  factory :enrollment_activity do
    association :enrollment
    association :activity
  end
end
