# frozen_string_literal: true

class Admin::Reports::EnrolledWithSessionsAndCourses < Admin::Reports::Base
  include Admin::Reports::CountryColumn

  self.label = 'Enrolled Students with Sessions and Courses'
  self.description = 'Course assignments of enrolled students for the camp year, by session and course, with year ' \
                     'in school and home state.'
  self.csv_title = 'enrolled_students_with_sessions_and_courses'
  self.sql = <<~SQL
    SELECT ad.country, co.description AS session, cor.title AS course, en.user_id,
      REPLACE(ad.lastname, ',', ' ') AS lastname,
      REPLACE(ad.firstname, ',', ' ') AS firstname, u.email,
      en.year_in_school, ad.state
      FROM course_assignments ca
      JOIN enrollments en ON ca.enrollment_id = en.id
      JOIN applicant_details AS ad ON ad.user_id = en.user_id
      JOIN courses AS cor ON ca.course_id = cor.id
      JOIN camp_occurrences AS co ON cor.camp_occurrence_id = co.id
      LEFT JOIN users AS u ON en.user_id = u.id
      WHERE en.campyear = :camp_year AND en.application_status = 'enrolled'
      ORDER BY co.description, cor.title
  SQL
end
