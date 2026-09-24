# frozen_string_literal: true

module Admin::ApplicationsHelper
  # Sessions the applicant registered for (the only valid session assignments).
  def admin_application_session_options(application)
    sessions = application.session_registrations.to_a
    sessions |= application.session_assignments.filter_map(&:camp_occurrence)
    sessions.sort_by(&:description).map { |session| [session.description, session.id] }
  end

  # Courses the applicant ranked, annotated with session, rank and remaining seats.
  def admin_application_course_options(application)
    rankings = application.course_preferences.index_by(&:course_id)
    courses = application.course_registrations.includes(:camp_occurrence).order(:camp_occurrence_id).to_a
    courses |= application.course_assignments.filter_map(&:course)

    courses.map do |course|
      rank = rankings[course.id]&.ranking
      label = "#{course.title}, #{course.camp_occurrence.description}, rank - #{rank || '—'}, available - #{course.remaining_spaces}"
      [label, course.id]
    end
  end

  def admin_application_status_options(application)
    options = Admin::ApplicationsController::STATUS_OPTIONS.dup
    options << 'withdrawn' if application.application_status == 'withdrawn'
    options
  end
end
