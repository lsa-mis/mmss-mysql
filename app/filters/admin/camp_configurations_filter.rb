# frozen_string_literal: true

# Index filters for Admin::CampConfigurationsController.
class Admin::CampConfigurationsFilter < Admin::Filter
  date_range :application_open
  date_range :application_close
  date_range :priority
  date_range :application_materials_due
  date_range :camper_acceptance_due
  boolean :active
end
