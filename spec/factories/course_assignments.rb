# frozen_string_literal: true

# == Schema Information
#
# Table name: course_assignments
#
#  id            :bigint           not null, primary key
#  enrollment_id :bigint           not null
#  course_id     :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  wait_list     :boolean          default(FALSE)
#
# Indexes
#
#  index_course_assignments_on_course_id      (course_id)
#  index_course_assignments_on_enrollment_id  (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id)
#  fk_rails_...  (enrollment_id => enrollments.id)
#
FactoryBot.define do
  factory :course_assignment do
    association :enrollment
    association :course

    wait_list { false }

    trait :waitlisted do
      wait_list { true }
    end

    trait :active do
      wait_list { false }
    end
  end
end
