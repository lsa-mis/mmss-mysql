# frozen_string_literal: true

class Admin::Reports::PendingCourseAssignmentsWithStudents < Admin::Reports::Base
  self.label = 'Pending Course Assignments with Students'
  self.description = 'Every course assignment for the camp year (whatever the offer status), by session and course, ' \
                     'with the assigned student.'
  self.csv_title = 'pending_course_assignments_with_students'
  self.sql = <<~SQL
    SELECT co.description, cor.title, en.user_id, REPLACE(ad.lastname, ',', ' ') AS lastname,
      REPLACE(ad.firstname, ',', ' ') AS firstname, u.email
      FROM course_assignments ca
      JOIN enrollments en ON ca.enrollment_id = en.id
      JOIN applicant_details AS ad ON ad.user_id = en.user_id
      JOIN courses AS cor ON ca.course_id = cor.id
      JOIN camp_occurrences AS co ON cor.camp_occurrence_id = co.id
      LEFT JOIN users AS u ON en.user_id = u.id
      WHERE en.campyear = :camp_year
      ORDER BY co.description, cor.title
  SQL
end
