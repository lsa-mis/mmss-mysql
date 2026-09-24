# frozen_string_literal: true

class Admin::Reports::CourseAssignments < Admin::Reports::Base
  self.label = 'Course Assignments'
  self.description = 'Class lists for the camp year: enrolled students per session and course with home town, ' \
                     'gender, age, year in school and personal statement. Repeated session/course cells are ' \
                     'left blank so the sheet reads as a list.'
  self.csv_title = 'course_assignments'
  self.sql = <<~SQL
    SELECT co.description AS session, cor.title AS course,
    REPLACE(ad.lastname, ',', ' ') AS lastname, REPLACE(ad.firstname, ',', ' ') AS firstname, u.email,
    ad.country, ad.state, ad.city,
    (CASE WHEN ad.gender = '' THEN NULL ELSE
    (SELECT genders.name FROM genders WHERE CAST(ad.gender AS UNSIGNED) = genders.id) END) as gender,
    TIMESTAMPDIFF(YEAR, ad.birthdate, CURDATE()) AS age,
    en.year_in_school, en.personal_statement
    FROM course_assignments ca
    JOIN enrollments en ON ca.enrollment_id = en.id
    JOIN applicant_details AS ad ON ad.user_id = en.user_id
    JOIN courses AS cor ON ca.course_id = cor.id
    JOIN camp_occurrences AS co ON cor.camp_occurrence_id = co.id
    LEFT JOIN users AS u ON en.user_id = u.id
    WHERE en.campyear = :camp_year AND en.application_status = 'enrolled'
    ORDER BY co.description ASC, cor.title, lastname
  SQL

  # Blank a session/course cell when it repeats the previous row's value.
  def rows
    previous = [nil, nil]

    result.rows.map do |row|
      current = row.first(2)
      row = row.dup
      row[0] = '' if current[0] == previous[0]
      row[1] = '' if current[1] == previous[1]
      previous = current
      row
    end
  end
end
