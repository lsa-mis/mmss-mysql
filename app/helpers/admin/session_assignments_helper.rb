# frozen_string_literal: true

module Admin::SessionAssignmentsHelper
  # accepted/declined, plus whatever is persisted so the select never clears the column.
  def admin_session_assignment_offer_status_options(session_assignment)
    options = Admin::SessionAssignmentsController::OFFER_STATUS_OPTIONS.dup
    current = session_assignment.offer_status
    options << current if current.present? && options.exclude?(current)
    options
  end
end
