# frozen_string_literal: true

class Admin::Reports::WaitlistedApplicationsWithCoursePreferences < Admin::Reports::Base
  self.label = 'Waitlisted Application with Course Preferences'
  self.description = 'Course preferences (ranking, course, session) of waitlisted applications for the camp year.'
  self.csv_title = 'waitlisted_applications_with_course_preferences'
  self.sql = <<~SQL
    SELECT u.email, ad.lastname, ad.firstname, cp.ranking, c.title, co.description
      FROM enrollments AS e
      JOIN course_preferences AS cp ON cp.enrollment_id = e.id
      JOIN courses AS c ON cp.course_id = c.id
      JOIN camp_occurrences AS co ON c.camp_occurrence_id = co.id
      JOIN applicant_details AS ad ON e.user_id = ad.user_id
      JOIN users AS u ON u.id = e.user_id
      WHERE campyear = :camp_year AND application_status = 'waitlisted'
      ORDER BY e.id, co.description, cp.ranking
  SQL
end
