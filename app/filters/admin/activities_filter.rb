# frozen_string_literal: true

# Index filters for Admin::ActivitiesController.
class Admin::ActivitiesFilter < Admin::Filter
  select :camp_occurrence_id, label: 'Session',
                              collection: -> { CampOccurrence.order(begin_date: :desc).no_any_session.map { |s| [s.display_name, s.id] } }
  select :description, collection: -> { Activity.distinct.order(:description).pluck(:description) }
  number :cost_cents, label: 'Cost (cents)'
  date_range :date_occurs
  boolean :active
end
