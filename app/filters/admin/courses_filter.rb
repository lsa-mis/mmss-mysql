# frozen_string_literal: true

# Index filters for Admin::CoursesController.
class Admin::CoursesFilter < Admin::Filter
  select :camp_occurrence_id, label: 'Session',
                              collection: -> { CampOccurrence.order(begin_date: :desc).no_any_session.map { |s| [s.display_name, s.id] } }
  text :title, match: :contains
  select :available_spaces, collection: -> { Course.where.not(available_spaces: nil).distinct.order(:available_spaces).pluck(:available_spaces) }
  select :status, collection: -> { Course.where.not(status: [nil, '']).distinct.order(:status).pluck(:status) }
end
