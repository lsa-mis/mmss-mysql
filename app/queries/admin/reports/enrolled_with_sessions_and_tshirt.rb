# frozen_string_literal: true

class Admin::Reports::EnrolledWithSessionsAndTshirt < Admin::Reports::Base
  self.label = 'Enrolled Students with Sessions and T-Shirt size'
  self.description = 'Enrolled students for the camp year, one row per assigned session, with their t-shirt size.'
  self.csv_title = 'enrolled_with_sessions_and_tshirt'
  self.sql = <<~SQL
    SELECT co.description AS session, en.user_id, REPLACE(ad.lastname, ',', ' ') AS lastname,
      REPLACE(ad.firstname, ',', ' ') AS firstname, u.email, ad.shirt_size
      FROM enrollments en
      JOIN applicant_details AS ad ON ad.user_id = en.user_id
      JOIN session_assignments AS sa ON sa.enrollment_id = en.id
      JOIN camp_occurrences AS co ON sa.camp_occurrence_id = co.id
      LEFT JOIN users AS u ON en.user_id = u.id
      WHERE en.campyear = :camp_year AND en.application_status = 'enrolled'
      ORDER BY co.description, ad.shirt_size
  SQL
end
