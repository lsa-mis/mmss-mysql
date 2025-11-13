# frozen_string_literal: true

# == Schema Information
#
# Table name: enrollment_activities
#
#  id            :bigint           not null, primary key
#  enrollment_id :bigint           not null
#  activity_id   :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_enrollment_activities_on_activity_id    (activity_id)
#  index_enrollment_activities_on_enrollment_id  (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (activity_id => activities.id)
#  fk_rails_...  (enrollment_id => enrollments.id)
#
FactoryBot.define do
  factory :enrollment_activity do
    association :enrollment
    association :activity
  end
end
