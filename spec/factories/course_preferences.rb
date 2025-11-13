# frozen_string_literal: true

# == Schema Information
#
# Table name: course_preferences
#
#  id            :bigint           not null, primary key
#  enrollment_id :bigint           not null
#  course_id     :bigint           not null
#  ranking       :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_course_preferences_on_course_id      (course_id)
#  index_course_preferences_on_enrollment_id  (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id)
#  fk_rails_...  (enrollment_id => enrollments.id)
#
FactoryBot.define do
  factory :course_preference do
    association :enrollment
    association :course

    ranking { rand(1..10) }
  end
end
