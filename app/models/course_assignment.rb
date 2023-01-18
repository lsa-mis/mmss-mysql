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

end
