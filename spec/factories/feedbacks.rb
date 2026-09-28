# frozen_string_literal: true

# == Schema Information
#
# Table name: feedbacks
#
#  id         :bigint           not null, primary key
#  genre      :string(255)
#  message    :string(255)
#  user_id    :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_feedbacks_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
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
