# frozen_string_literal: true

# Select options for the "Enrollment" / "Applicant" pickers shared by the Applicant Info
# resources (course assignments, session selections, travels, ...): current-year applications
# labelled "Lastname, Firstname - email", alphabetically. Loaded in one query per render (the
# ActiveAdmin collections called `display_name` per row, which was two queries each).
#
# `include:` keeps a record's persisted enrollment selectable when it belongs to an older camp
# year, so editing an old record does not silently clear the association.
class Admin::EnrollmentOptions
  def self.current_camp(include: nil)
    enrollments = Enrollment.current_camp_year_applications.preload(:user, :applicant_detail).to_a
    enrollments << include if include && enrollments.none? { |enrollment| enrollment.id == include.id }
    enrollments.map { |enrollment| [label(enrollment), enrollment.id] }
               .sort_by { |label, _id| label.downcase }
  end

  def self.label(enrollment)
    name = enrollment.applicant_detail&.full_name
    email = enrollment.user&.email
    [name, email].compact_blank.join(' - ').presence || "Application ##{enrollment.id}"
  end
end
