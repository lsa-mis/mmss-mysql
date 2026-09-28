# frozen_string_literal: true

# The legacy report first plucked the enrollment ids with more than one accepted session
# assignment (SessionAssignment.accepted, i.e. the current camp year) in Ruby and interpolated
# them; the same set is now a subquery bound to the selected camp year.
class Admin::Reports::EnrolledForMoreThanOneSession < Admin::Reports::Base
  include Admin::Reports::CountryColumn

  self.label = 'Enrolled for More than One Session'
  self.description = 'Course assignments of enrolled students for the camp year who accepted more than one ' \
                     'session, by student and session.'
  self.csv_title = 'enrolled_for_more_than_one_session'
  self.sql = <<~SQL
    SELECT ad.country,  en.user_id,
      REPLACE(ad.lastname, ',', ' ') AS lastname, REPLACE(ad.firstname, ',', ' ') AS firstname,
      u.email, co.description AS session, cor.title AS course,
      en.year_in_school, ad.state
      FROM course_assignments ca
      JOIN enrollments en ON ca.enrollment_id = en.id
      JOIN applicant_details AS ad ON ad.user_id = en.user_id
      JOIN courses AS cor ON ca.course_id = cor.id
      JOIN camp_occurrences AS co ON cor.camp_occurrence_id = co.id
      LEFT JOIN users AS u ON en.user_id = u.id
      WHERE en.campyear = :camp_year
        AND en.application_status = 'enrolled'
        AND en.id IN (
          SELECT sa.enrollment_id
          FROM session_assignments AS sa
          JOIN enrollments AS e2 ON e2.id = sa.enrollment_id
          WHERE e2.campyear = :camp_year AND sa.offer_status = 'accepted'
          GROUP BY sa.enrollment_id
          HAVING COUNT(*) > 1
        )
      ORDER BY u.email, co.description
  SQL
end
