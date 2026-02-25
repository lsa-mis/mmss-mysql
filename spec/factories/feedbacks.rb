# frozen_string_literal: true

FactoryBot.define do
  factory :feedback do
    association :user
    genre { "page_error" }
    message { Faker::Lorem.sentence(word_count: 10) }

    trait :page_error do
      genre { "page_error" }
    end

    trait :layout_issue do
      genre { "layout_issue" }
    end

    trait :suggestion do
      genre { "suggestion" }
    end

    trait :max_message do
      message { "x" * Feedback::MESSAGE_MAX_LENGTH }
    end
  end
end
