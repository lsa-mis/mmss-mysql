# frozen_string_literal: true

# "Offer accepted" applications for the active camp that still owe money, with the balance computed
# in SQL (same arithmetic as PaymentState#balance_due and the offer_accepted_with_balance_due report:
# accepted session costs + activity costs in those sessions + application fee when required,
# minus awarded financial aid and successful payments).
#
#   query = Admin::BalanceDueQuery.new
#   query.count                  # total applications with a positive balance
#   query.enrollments(limit: 20) # Enrollment records ordered by name, each with #balance_due_cents
#
#   # Any Enrollment relation (index pages, CSV exports): adds a `balance_due_cents` column so no
#   # per-row PaymentState calls are needed.
#   Admin::BalanceDueQuery.with_balance_due(relation).each { |e| e.balance_due_cents }
class Admin::BalanceDueQuery
  def self.with_balance_due(relation, camp: CampConfiguration.active.first)
    new(camp).with_balance_due(relation)
  end

  def initialize(camp = CampConfiguration.active.first)
    @camp = camp
  end

  # Adds `balance_due_cents` to the relation's select list. Without an active camp no fee and no
  # payments are counted, exactly like PaymentState.
  def with_balance_due(relation)
    relation = relation.select("#{relation.model.table_name}.*") if relation.select_values.empty?
    relation.select("(#{balance_sql}) AS balance_due_cents")
  end

  def count
    @camp ? with_balance.count : 0
  end

  def enrollments(limit:)
    return [] unless @camp

    with_balance.select("enrollments.*, (#{balance_sql}) AS balance_due_cents")
                .preload(:user, :applicant_detail)
                .order('applicant_details.lastname, applicant_details.firstname')
                .limit(limit)
  end

  private

  def base
    Enrollment.joins(:applicant_detail)
              .where(campyear: @camp.camp_year, application_status: 'offer accepted')
  end

  def with_balance
    base.where("(#{balance_sql}) > 0")
  end

  def balance_sql
    @balance_sql ||= Enrollment.sanitize_sql_array([<<~SQL.squish, @camp&.application_fee_cents.to_i, @camp&.camp_year])
      COALESCE((SELECT SUM(COALESCE(co.cost_cents, 0))
                FROM session_assignments sa JOIN camp_occurrences co ON co.id = sa.camp_occurrence_id
                WHERE sa.enrollment_id = enrollments.id AND sa.offer_status = 'accepted'), 0)
      + COALESCE((SELECT SUM(COALESCE(a.cost_cents, 0))
                  FROM enrollment_activities ea JOIN activities a ON a.id = ea.activity_id
                  WHERE ea.enrollment_id = enrollments.id
                    AND a.camp_occurrence_id IN (SELECT camp_occurrence_id FROM session_assignments
                                                 WHERE enrollment_id = enrollments.id AND offer_status = 'accepted')), 0)
      + CASE WHEN enrollments.application_fee_required THEN ? ELSE 0 END
      - COALESCE((SELECT SUM(amount_cents) FROM financial_aids
                  WHERE enrollment_id = enrollments.id AND status = 'awarded'), 0)
      - COALESCE((SELECT SUM(CAST(total_amount AS SIGNED)) FROM payments
                  WHERE user_id = enrollments.user_id AND camp_year = ? AND transaction_status = '1'), 0)
    SQL
  end
end
