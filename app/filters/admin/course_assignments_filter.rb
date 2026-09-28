# frozen_string_literal: true

class Admin::CourseAssignmentsFilter < Admin::Filter
  select :enrollment_id, label: 'Enrollment', collection: -> { Admin::EnrollmentOptions.current_camp }
  select :course_id, label: 'Course', collection: -> { Admin::CampOptions.courses }
end
