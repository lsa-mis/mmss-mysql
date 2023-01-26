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
require 'rails_helper'

RSpec.describe CourseAssignment, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
