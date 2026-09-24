# frozen_string_literal: true

# Activity descriptions differ between environments ("Dormitory (Residential Stay)" in development,
# "Residential Stay" in production), hence the case-insensitive LIKE on both. The legacy report
# plucked Enrollment.enrolled (current camp year) in Ruby and interpolated the ids; the same set is
# now a subquery bound to the selected camp year.
class Admin::Reports::DormByGenderBySession < Admin::Reports::Base
  include Admin::Reports::CountryColumn

  self.label = 'Enrolled with Dormitories'
  self.description = 'Enrolled students for the camp year who chose the dormitory / residential stay activity of ' \
                     'an accepted session, with gender and room mate request.'
  self.csv_title = 'dorm_by_gender_by_session'
  self.sql = <<~SQL
    SELECT ad.country, a.description AS 'Event Activity', co.description AS Session, ad.lastname,
      ad.firstname, u.email,
      COALESCE(g.name, 'Not Specified') as gender,
      e.room_mate_request, ad.city, ad.state
      FROM session_assignments AS sa
      JOIN enrollments AS e ON e.id = sa.enrollment_id
      JOIN enrollment_activities AS ea ON ea.enrollment_id = sa.enrollment_id
      JOIN activities as a ON a.id = ea.activity_id AND a.camp_occurrence_id = sa.camp_occurrence_id
      JOIN camp_occurrences AS co ON co.id = a.camp_occurrence_id
      JOIN applicant_details AS ad ON ad.user_id = e.user_id
      JOIN users AS u ON u.id = ad.user_id
      LEFT JOIN genders AS g ON CAST(ad.gender AS UNSIGNED) = g.id
      WHERE sa.enrollment_id IN (
          SELECT id
          FROM enrollments
          WHERE application_status = 'enrolled' AND campyear = :camp_year
        )
        AND sa.offer_status = 'accepted'
        AND (LOWER(a.description) LIKE LOWER('%dormitory%') OR LOWER(a.description) LIKE LOWER('%residential stay%'))
      ORDER BY co.description, a.description, ad.lastname, e.id
  SQL
end
