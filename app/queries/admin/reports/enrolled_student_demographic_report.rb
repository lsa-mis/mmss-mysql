# frozen_string_literal: true

class Admin::Reports::EnrolledStudentDemographicReport < Admin::Reports::Base
  include Admin::Reports::CountryColumn

  self.label = 'Enrolled Students Demographic Report'
  self.description = 'Country, gender, year in school, demographic and international flag of every enrolled ' \
                     'student for the camp year (no names).'
  self.csv_title = 'enrolled_student_demographic_report'
  self.sql = <<~SQL
    SELECT ad.country,
    (CASE WHEN ad.gender = '' THEN NULL ELSE
    (SELECT genders.name FROM genders WHERE CAST(ad.gender AS UNSIGNED) = genders.id) END) as gender,
    e.year_in_school,
    CASE
      WHEN d.name = 'Other' AND ad.demographic_other IS NOT NULL THEN CONCAT(d.name, ' - ', ad.demographic_other)
      ELSE d.name
    END AS demographic,
    e.international
    FROM enrollments AS e
    LEFT JOIN users AS u ON e.user_id = u.id
    LEFT JOIN applicant_details AS ad ON ad.user_id = e.user_id
    LEFT JOIN demographics AS d ON d.id = ad.demographic_id
    WHERE e.application_status = 'enrolled'
    AND e.campyear = :camp_year
    ORDER BY country, gender, year_in_school
  SQL
end
