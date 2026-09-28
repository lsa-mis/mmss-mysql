# frozen_string_literal: true

# Select options scoped to the active camp sessions, shared by the Applicant Info filters and
# forms (courses, sessions and activities pickers). Each returns `[label, id]` pairs.
#
# `include:` keeps a record's persisted association selectable when it belongs to a session that
# is no longer active (otherwise the select would submit blank and clear the column).
class Admin::CampOptions
  def self.courses(include: nil)
    courses = Course.where(camp_occurrence_id: CampOccurrence.active)
                    .includes(:camp_occurrence).order(:camp_occurrence_id, :title).to_a
    with_included(courses, include).map { |course| [course.display_name, course.id] }
  end

  def self.sessions(include: nil)
    sessions = CampOccurrence.active.no_any_session.to_a
    with_included(sessions, include).map { |session| [session.display_name, session.id] }
  end

  def self.activities(include: nil)
    activities = Activity.where(camp_occurrence_id: CampOccurrence.active)
                         .includes(:camp_occurrence).order(:camp_occurrence_id, :description).to_a
    with_included(activities, include).map { |activity| [activity.display_name, activity.id] }
  end

  def self.with_included(records, include)
    return records if include.nil? || records.any? { |record| record.id == include.id }

    records + [include]
  end
  private_class_method :with_included
end
