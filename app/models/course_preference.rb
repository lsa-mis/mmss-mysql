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
class CoursePreference < ApplicationRecord
  belongs_to :enrollment
  belongs_to :course

  def self.ransackable_associations(auth_object = nil)
    ["course", "enrollment"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["course_id", "created_at", "enrollment_id", "id", "ranking", "updated_at"]
  end
end
