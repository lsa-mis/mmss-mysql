# frozen_string_literal: true

class Admin::Reports::EnrolledWithAddressesAndMore < Admin::Reports::Base
  self.label = 'Enrolled with Addresses, Birthdate, Gender, Graduation Year'
  self.description = 'Enrolled students for the camp year with home address, country, birthdate, gender, ' \
                     'demographic, graduation year and year in school.'
  self.csv_title = 'enrolled_with_addresses_and_more'
  self.sql = <<~SQL
    SELECT
      CONCAT(REPLACE(ad.firstname, ',', ' '), ' ', REPLACE(ad.lastname, ',', ' ')) AS name,
      REPLACE(ad.lastname, ',', ' ') AS lastname,
      REPLACE(ad.firstname, ',', ' ') AS firstname,
      u.email,
      ad.address1, ad.address2, ad.city, ad.state, ad.state_non_us, ad.postalcode,
      ad.country, ad.birthdate,
      (CASE WHEN ad.gender = '' THEN NULL ELSE
      (SELECT genders.name FROM genders WHERE CAST(ad.gender AS UNSIGNED) = genders.id) END) as gender,
      d.name AS demographic,
      CASE WHEN d.name = 'Other' THEN ad.demographic_other ELSE NULL END as demographic_other,
      e.anticipated_graduation_year as graduation_year,
      e.year_in_school
      FROM enrollments AS e
      LEFT JOIN users AS u ON e.user_id = u.id
      LEFT JOIN applicant_details AS ad ON ad.user_id = e.user_id
      LEFT JOIN demographics AS d ON d.id = ad.demographic_id
      WHERE e.application_status = 'enrolled'
      AND e.campyear = :camp_year
      ORDER BY name
  SQL
end
