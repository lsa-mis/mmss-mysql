# frozen_string_literal: true

class Admin::DashboardController < Admin::BaseController
  RECENT_LIMIT = 10
  BALANCE_DUE_LIMIT = 20

  def index
    @active_camp = CampConfiguration.active.first
    return unless @active_camp

    @recent_applications = Enrollment.current_camp_year_applications
                                     .includes(:user, :applicant_detail)
                                     .order(created_at: :desc).limit(RECENT_LIMIT)
    @recent_payments = Payment.current_camp_payments
                              .includes(user: :applicant_detail)
                              .order(created_at: :desc).limit(RECENT_LIMIT)
    balance_due_query = Admin::BalanceDueQuery.new(@active_camp)
    @balance_due = balance_due_query.enrollments(limit: BALANCE_DUE_LIMIT)
    @balance_due_total = balance_due_query.count
    @pending_financial_aids = FinancialAid.where(enrollment: Enrollment.current_camp_year_applications, status: 'pending')
                                          .includes(enrollment: %i[user applicant_detail])
    @sessions = CampOccurrence.active.to_a
    @session_stats = session_stats(@sessions)
    @camp_notes = Campnote.all.select { |note| note.opendate.present? && note.closedate.present? && (note.opendate..note.closedate).cover?(Time.current) }
  end

  private

  def session_stats(sessions)
    enrolled_ids = Enrollment.enrolled.pluck(:id)

    sessions.map do |session|
      {
        session: session,
        applied: SessionActivity.where(camp_occurrence_id: session.id).count,
        assigned: SessionAssignment.where(camp_occurrence_id: session.id).count,
        enrolled: SessionAssignment.where(camp_occurrence_id: session.id, enrollment_id: enrolled_ids).distinct.count(:enrollment_id)
      }
    end
  end
end
