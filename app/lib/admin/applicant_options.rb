# frozen_string_literal: true

# Select options for the applicant pickers on the Money resources: current-year applications
# labelled "Lastname, Firstname - email", alphabetically, loaded in one query per render (the
# ActiveAdmin collections called `display_name` per row, two queries each).
#
# `include:` keeps a record's persisted applicant selectable when it belongs to an older camp
# year, so editing an old record does not silently clear the association.
class Admin::ApplicantOptions
  # [label, enrollment_id] pairs (Financial Aid Requests).
  def self.enrollments(include: nil)
    build(include: include) { |enrollment| enrollment.id }
  end

  # [label, user_id] pairs (Payments belong to the user, not the enrollment).
  def self.users(include: nil)
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
