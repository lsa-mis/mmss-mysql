# frozen_string_literal: true

class CourseAssignmentsController < InheritedResources::Base
  before_action :authenticate_admin!

  private

    def course_assignment_params
      params.require(:course_assignment).permit(:enrollment_id, :course_id, :wait_list)
    end

end
