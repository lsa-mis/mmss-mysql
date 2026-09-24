# frozen_string_literal: true

# Select options for the "Enrollment" / "Applicant" pickers shared by the Applicant Info and
# Money resources (course assignments, session selections, travels, financial aid, payments, ...):
# current-year applications labelled "Lastname, Firstname - email", alphabetically. Loaded in one
# query per render (the ActiveAdmin collections called `display_name` per row, which was two
# queries each).
#
# `include:` keeps a record's persisted enrollment selectable when it belongs to an older camp
# year, so editing an old record does not silently clear the association.
class Admin::EnrollmentOptions
  # [label, enrollment_id] pairs.
  def self.current_camp(include: nil)
    build(include: include) { |enrollment| enrollment.id }
  end

  # [label, user_id] pairs, for records that belong to the user rather than the enrollment
  # (Payments).
  def self.current_camp_users(include: nil)
    build(include: include) { |enrollment| enrollment.user_id }
  end

  def self.label(enrollment)
    name = enrollment.applicant_detail&.full_name
    email = enrollment.user&.email
    [name, email].compact_blank.join(' - ').presence || "Application ##{enrollment.id}"
  end

  def self.build(include:)
    enrollments = Enrollment.current_camp_year_applications.preload(:user, :applicant_detail).to_a
    enrollments << include if include && enrollments.none? { |enrollment| enrollment.id == include.id }
    enrollments.map { |enrollment| [label(enrollment), yield(enrollment)] }
               .uniq(&:last)
               .sort_by { |label, _id| label.downcase }
  end
  private_class_method :build
end
