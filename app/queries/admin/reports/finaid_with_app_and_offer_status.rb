# frozen_string_literal: true

class Admin::Reports::FinaidWithAppAndOfferStatus < Admin::Reports::Base
  self.label = 'Finaid with App and Offer Status'
  self.description = 'Applicants with a financial aid request for the camp year, with their application and ' \
                     'offer status.'
  self.csv_title = 'finaid_with_app_and_offer_status'
  self.sql = <<~SQL
    SELECT ad.firstname, ad.lastname, u.email, enroll.application_status, enroll.offer_status
      FROM financial_aids AS fa
      JOIN enrollments AS enroll ON fa.enrollment_id = enroll.id
      JOIN applicant_details AS ad ON enroll.user_id = ad.user_id
      JOIN users AS u ON enroll.user_id = u.id
      WHERE enroll.campyear = :camp_year
      ORDER BY enroll.application_status, enroll.offer_status
  SQL
end
