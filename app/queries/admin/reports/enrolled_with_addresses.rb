# frozen_string_literal: true

class Admin::Reports::EnrolledWithAddresses < Admin::Reports::Base
  include Admin::Reports::CountryColumn

  self.label = 'Enrolled with Addresses and Parents Information'
  self.description = 'Enrolled students for the camp year with their email, parent name, phone and email, and ' \
                     'home address.'
  self.csv_title = 'enrolled_with_addresses_and_parents_information'
  self.sql = <<~SQL
    Select ad.country, CONCAT(REPLACE(ad.firstname, ',', ' '), ' ', REPLACE(ad.lastname, ',', ' ')) AS name,
      REPLACE(ad.lastname, ',', ' ') AS lastname, REPLACE(ad.firstname, ',', ' ') AS firstname, u.email,
      ad.parentname, ad.parentphone, ad.parentemail,
      ad.address1, ad.address2, ad.city, ad.state, ad.state_non_us, ad.postalcode
      FROM enrollments AS e
      LEFT JOIN users AS u ON e.user_id = u.id
      JOIN applicant_details AS ad ON ad.user_id = e.user_id
      WHERE e.application_status = 'enrolled' AND e.campyear = :camp_year
      ORDER BY name
  SQL
end
