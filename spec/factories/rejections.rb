# frozen_string_literal: true

# == Schema Information
#
# Table name: rejections
#
#  id            :bigint           not null, primary key
#  enrollment_id :bigint           not null
#  reason        :text(65535)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_rejections_on_enrollment_id  (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (enrollment_id => enrollments.id)
#
FactoryBot.define do
  factory :rejection do
    association :enrollment

    reason { Faker::Lorem.paragraph }

    trait :incomplete_application do
      reason { 'Application was incomplete' }
    end

    trait :does_not_meet_requirements do
      reason { 'Does not meet program requirements' }
    end
  end
end
