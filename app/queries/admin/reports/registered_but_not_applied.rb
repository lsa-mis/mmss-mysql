# frozen_string_literal: true

class Admin::Reports::RegisteredButNotApplied < Admin::Reports::Base
  self.label = 'Registered but not Applied'
  self.description = 'Users who filled in their applicant details but have no application for the camp year, ' \
                     'with their last login and when the details were created.'
  self.csv_title = 'registered_but_not_applied'
  self.sql = <<~SQL
    SELECT u.id, u.email,
      CONCAT(REPLACE(ad.firstname, ',', ' '), ' ',
            REPLACE(ad.lastname, ',', ' ')) AS name,
      DATE_FORMAT(u.current_sign_in_at, '%Y-%m-%d') AS 'Last user login',
      DATE_FORMAT(ad.created_at, '%Y-%m-%d') AS 'Applicant Details created'
    FROM users AS u
    JOIN applicant_details AS ad on u.id = ad.user_id
    WHERE ad.user_id NOT IN (
      SELECT e.user_id
      FROM enrollments AS e
      WHERE e.campyear = :camp_year
    )
    ORDER BY ad.created_at DESC, u.current_sign_in_at DESC
  SQL
end
