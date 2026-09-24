# frozen_string_literal: true

class Admin::Reports::AllCompleteApps < Admin::Reports::Base
  self.label = 'All Complete Applications'
  self.description = 'Every application with status "application complete" for the camp year: applicant, ' \
                     'contact and parent details, high school, statement, recommender and financial aid request.'
  self.csv_title = 'all_complete_applications'
  self.sql = <<~SQL
    SELECT DATE_FORMAT(e.updated_at, '%Y-%m-%d') AS 'Last Update',
      CONCAT(REPLACE(ad.firstname, ',', ' '), ' ', REPLACE(ad.lastname, ',', ' ')) AS name,
      u.email,
      (CASE WHEN ad.gender = '' THEN NULL ELSE
      (SELECT genders.name FROM genders WHERE CAST(ad.gender AS UNSIGNED) = genders.id) END) as gender,
      ad.us_citizen as us_citizen,
      CASE
        WHEN d.name = 'Other' AND ad.demographic_other IS NOT NULL THEN CONCAT(d.name, ' - ', ad.demographic_other)
        ELSE d.name
      END AS demographic,
      ad.birthdate as birthdate, ad.diet_restrictions as diet_restrictions,
      ad.shirt_size as shirt_size, CONCAT(ad.address1, ' ', ad.address2, ' ', ad.city, ' ',
      ad.state, ' ', ad.state_non_us, ' ', ad.postalcode, ' ', ad.country) AS address,
      ad.phone as phone, ad.parentname as parentname,
      CONCAT(ad.parentaddress1, ' ', ad.parentaddress2, ' ', ad.parentcity, ' ', ad.parentstate, ' ',
      ad.parentstate_non_us, ' ', ad.parentzip, ' ', ad.parentcountry) AS parent_address,
      ad.parentphone as parentphone, ad.parentworkphone as parentworkphone, ad.parentemail as parentemail,
      e.user_id as user_id, e.international as international, e.high_school_name as high_school_name,
      CONCAT(e.high_school_address1, ' ', e.high_school_address2, ' ',
      e.high_school_city, ' ', e.high_school_state, ' ',
      e.high_school_non_us, ' ', e.high_school_postalcode, ' ',
      e.high_school_country) AS high_school_address, e.year_in_school as year_in_school,
      e.anticipated_graduation_year as anticipated_graduation_year, e.room_mate_request as room_mate_request,
      e.personal_statement as personal_statement, e.notes as notes,
      e.application_status as application_status, e.offer_status as offer_status,
      r.email AS recommender_email,
      CONCAT(REPLACE(r.lastname, ',', ' '), ' ', REPLACE(r.firstname, ',', ' ')) AS recommender_name,
      r.organization AS recommender_organization,
      fa.amount_cents AS fin_aid_amount, fa.source AS fin_aid_source, fa.note AS fin_aid_note,
      fa.status AS fin_aid_status
      FROM enrollments AS e
      LEFT JOIN users AS u ON e.user_id = u.id
      LEFT JOIN applicant_details AS ad ON ad.user_id = e.user_id
      LEFT JOIN recommendations AS r ON r.enrollment_id = e.id
      LEFT JOIN financial_aids AS fa ON fa.enrollment_id = e.id
      LEFT JOIN demographics AS d ON d.id = ad.demographic_id
      WHERE e.application_status = 'application complete' AND e.campyear = :camp_year
      ORDER BY name
  SQL

  private

  # The legacy report divided the cents in SQL, which came back as a BigDecimal and was written in
  # scientific notation; the amount is now formatted as money like every other admin export.
  def transform_row(row)
    index = column_index(:fin_aid_amount)
    row[index] = money(row[index]) unless row[index].nil?
    row
  end
end
