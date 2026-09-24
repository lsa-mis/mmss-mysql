# frozen_string_literal: true

module Admin::CoursesHelper
  # open/closed plus whatever status the course already has, so the select never submits a value
  # that silently changes the persisted one.
  def admin_course_status_options(course)
    options = course_status.dup
    current = course.status
    options << [current, current] if current.present? && options.none? { |_label, value| value == current }
    options
  end
end
