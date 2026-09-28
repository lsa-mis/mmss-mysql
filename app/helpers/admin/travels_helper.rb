# frozen_string_literal: true

module Admin::TravelsHelper
  # Sessions offered for the arrival/departure selects: active sessions for a new travel, the
  # applicant's assigned sessions when editing (as in ActiveAdmin), plus the persisted value.
  def admin_travel_session_options(travel, current)
    sessions = if travel.persisted? && travel.enrollment
                 travel.enrollment.session_assignments.includes(:camp_occurrence).map { |assignment| assignment.camp_occurrence.description_with_month_and_day }
               else
                 CampOccurrence.active.no_any_session.map(&:description_with_month_and_day)
               end
    sessions << current if current.present? && sessions.exclude?(current)
    sessions
  end

  def admin_travel_transport_options(current)
    options = transportation.dup
    options << current if current.present? && options.exclude?(current)
    options
  end

  # "%A, %d %b %Y" / "%I:%M %p", the formats the ActiveAdmin index used.
  def admin_travel_date(date) = date.present? ? show_date(date) : admin_empty_value

  def admin_travel_time(time) = time.present? ? show_time(time) : admin_empty_value
end
