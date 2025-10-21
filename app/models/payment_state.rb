# frozen_string_literal: true

class PaymentState
  def initialize(enrollment)
    @curr_enrollment = enrollment
  end

  def registration_activities
    @curr_enrollment.registration_activities.order(camp_occurrence_id: :asc)
  end

  def session_registrations
    @curr_enrollment.session_registrations.order(description: :asc)
  end

  def current_application_status
    @curr_enrollment.application_status
  end

  def finaids
    @curr_enrollment.financial_aids
  end

  def has_any_session
    @session_registrations.pluck(:description).include?('Any Session')
  end

  def finaids_ttl
    finaids.pluck(:amount_cents).sum
  end

  def finaids_awarded_ttl
    finaids.where(status: 'awarded').pluck(:amount_cents).sum
  end

  def users_current_payments
    @curr_enrollment.user.payments.current_camp_payments
  end

  def ttl_paid
    @curr_enrollment.user.payments.status1_current_camp_payments.pluck(:total_amount).map(&:to_i).sum
  end

  def total_cost
    base_cost = cost_sessions_ttl + cost_activities_ttl
    active_camp = CampConfiguration.active.first

    # Include application fee only if it was required for this enrollment
    if @curr_enrollment.application_fee_required
      base_cost + active_camp.application_fee_cents
    else
      base_cost
    end
  end

  def balance_due
    total_cost.to_i - finaids_awarded_ttl.to_i - ttl_paid.to_i
  end

  def assigned_sessions_ids
    SessionAssignment.where(enrollment_id: @curr_enrollment, offer_status: 'accepted').pluck(:camp_occurrence_id)
  end

  def cost_sessions_ttl
    # sum of each session use is assigned to
    CampOccurrence.where(id: assigned_sessions_ids).pluck(:cost_cents).sum
  end

  def cost_activities_ttl
    activity_ids = EnrollmentActivity.where(enrollment_id: @curr_enrollment).pluck(:activity_id)
    Activity.where(id: activity_ids, camp_occurrence_id: assigned_sessions_ids).pluck(:cost_cents).sum
  end
end
