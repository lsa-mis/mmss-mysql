# frozen_string_literal: true

# Balance due is computed in SQL with the same arithmetic as PaymentState#balance_due and
# Admin::BalanceDueQuery: accepted session costs + costs of activities in those sessions
# + the camp's application fee when required, minus awarded financial aid and successful payments.
class Admin::Reports::OfferAcceptedWithBalanceDue < Admin::Reports::Base
  self.label = 'Offer Accepted with Balance Due'
  self.description = 'Applicants who accepted their offer for the camp year, with date of birth, gender, parent ' \
                     'email and the balance still due.'
  self.csv_title = 'offer_accepted_with_balance_due'
  self.sql = <<~SQL
    SELECT
      CONCAT(REPLACE(ad.firstname, ',', ' '), ' ', REPLACE(ad.lastname, ',', ' ')) AS name,
      DATE_FORMAT(ad.birthdate, '%Y-%m-%d') AS 'date_of_birth',
      (CASE WHEN ad.gender = '' THEN NULL ELSE
      (SELECT genders.name FROM genders WHERE CAST(ad.gender AS UNSIGNED) = genders.id) END) as gender,
      ad.parentemail AS 'parent_email',
      (
        COALESCE((
          SELECT SUM(COALESCE(co.cost_cents, 0))
          FROM session_assignments sa
          JOIN camp_occurrences co ON sa.camp_occurrence_id = co.id
          WHERE sa.enrollment_id = e.id AND sa.offer_status = 'accepted'
        ), 0) +
        COALESCE((
          SELECT SUM(COALESCE(a.cost_cents, 0))
          FROM enrollment_activities ea
          JOIN activities a ON ea.activity_id = a.id
          WHERE ea.enrollment_id = e.id
          AND a.camp_occurrence_id IN (
            SELECT camp_occurrence_id
            FROM session_assignments
            WHERE enrollment_id = e.id AND offer_status = 'accepted'
          )
        ), 0) +
        CASE WHEN e.application_fee_required THEN
          COALESCE((SELECT application_fee_cents FROM camp_configurations WHERE id = :camp_id), 0)
        ELSE 0 END
      ) -
      COALESCE((
        SELECT SUM(amount_cents)
        FROM financial_aids
        WHERE enrollment_id = e.id AND status = 'awarded'
      ), 0) -
      COALESCE((
        SELECT SUM(CAST(total_amount AS UNSIGNED))
        FROM payments
        WHERE user_id = e.user_id AND camp_year = :camp_year AND transaction_status = '1'
      ), 0)
      AS 'balance_due'
      FROM enrollments AS e
      LEFT JOIN users AS u ON e.user_id = u.id
      LEFT JOIN applicant_details AS ad ON ad.user_id = e.user_id
      WHERE e.application_status = 'offer accepted'
      AND e.campyear = :camp_year
      ORDER BY name
  SQL

  private

  def transform_row(row)
    index = column_index(:balance_due)
    row[index] = money(row[index])
    row
  end
end
