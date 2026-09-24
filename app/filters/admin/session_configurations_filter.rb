# frozen_string_literal: true

# Index filters for Admin::SessionConfigurationsController (CampOccurrence).
class Admin::SessionConfigurationsFilter < Admin::Filter
  select :camp_configuration_id, label: 'Camp',
                                 collection: -> { CampConfiguration.order(camp_year: :desc).pluck(:camp_year, :id) }
  select :description, collection: -> { CampOccurrence.distinct.order(:description).pluck(:description) }
  date_range :begin_date
  date_range :end_date
  boolean :active
end
