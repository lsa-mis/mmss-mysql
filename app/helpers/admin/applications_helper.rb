# frozen_string_literal: true

module Admin::ApplicationsHelper
  # "Lastname, Firstname" of the applicant, falling back to the account email.
  def admin_applicant_name(enrollment)
    enrollment.applicant_detail&.full_name || enrollment.user.email
  end

  # Applicant name linking to the application's admin show page (the "Enrollment"/"Applicant"
  # column shared by the Applicant Info resources).
  def admin_applicant_link(enrollment, with_email: false)
    return admin_empty_value if enrollment.nil?

    link = link_to(admin_applicant_name(enrollment), admin_application_path(enrollment), class: 'font-medium')
    return link unless with_email

    safe_join([link, tag.div(enrollment.user.email, class: 'text-xs text-slate-500')])
  end

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

  # The persisted status is always selectable (e.g. `waitlisted`, `rejected`, `withdrawn` are set
  # by other flows), otherwise the select would submit blank and clear it.
  def admin_application_status_options(application)
    options = Admin::ApplicationsController::STATUS_OPTIONS.dup
    current = application.application_status
    options << current if current.present? && options.exclude?(current)
    options
  end
end
