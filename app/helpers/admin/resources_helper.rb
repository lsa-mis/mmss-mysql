# frozen_string_literal: true

# Maps models to their admin show pages. Models whose resource name differs from the model
# name (ActiveAdmin's `as:`) are listed explicitly; everything else falls back to the
# conventional `admin_<model>_path`. Resources not yet ported return the legacy route instead.
module Admin::ResourcesHelper
  ROUTE_NAMES = {
    'Enrollment' => 'application',
    'SessionActivity' => 'session_selection',
    'EnrollmentActivity' => 'applicant_activity',
    'FinancialAid' => 'financial_aid_request',
    'CampOccurrence' => 'session_configuration',
    'Gender' => 'gender_type'
  }.freeze

  def admin_resource_route_name(record)
    ROUTE_NAMES.fetch(record.class.name) { record.class.model_name.singular }
  end

  # Path to the record's admin show page: the new admin when the route exists, otherwise the
  # legacy ActiveAdmin page. Returns nil when neither exists.
  def admin_resource_path(record)
    return nil if record.nil?

    name = admin_resource_route_name(record)
    if respond_to?(:"admin_#{name}_path")
      public_send(:"admin_#{name}_path", record)
    elsif respond_to?(:"legacy_admin_#{name}_path")
      public_send(:"legacy_admin_#{name}_path", record)
    end
  end

  def admin_resource_link(record, text = nil)
    return admin_empty_value if record.nil?

    text ||= record.try(:display_name) || record.try(:name) || "#{record.class.model_name.human} ##{record.id}"
    path = admin_resource_path(record)
    path ? link_to(text, path) : text
  end
end
