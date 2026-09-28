# frozen_string_literal: true

# Maps models to their admin show pages. Models whose resource name differs from the model
# name (the legacy admin's resource names, kept for the routes) are listed explicitly;
# everything else falls back to the conventional `admin_<model>_path`.
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

  # Path to the record's admin show page, or nil when the model has no admin resource.
  def admin_resource_path(record)
    return nil if record.nil?

    helper = :"admin_#{admin_resource_route_name(record)}_path"
    public_send(helper, record) if respond_to?(helper)
  end

  def admin_resource_link(record, text = nil)
    return admin_empty_value if record.nil?

    text ||= record.try(:display_name) || record.try(:name) || "#{record.class.model_name.human} ##{record.id}"
    path = admin_resource_path(record)
    path ? link_to(text, path) : text
  end
end
