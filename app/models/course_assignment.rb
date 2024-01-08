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
class CourseAssignment < ApplicationRecord
  belongs_to :enrollment
  belongs_to :course


  scope :number_of_assignments, ->(course_id="") {where(course_id: course_id, wait_list: false).size}
  scope :wait_list_number, -> (course_id="") { where(course_id: course_id, wait_list: true).size }

  def self.ransackable_associations(auth_object = nil)
    ["course", "enrollment"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["course_id", "created_at", "enrollment_id", "id", "updated_at", "wait_list"]
  end

end
