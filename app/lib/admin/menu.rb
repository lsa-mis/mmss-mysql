# frozen_string_literal: true

# Sidebar navigation for the admin layout. Mirrors the four ActiveAdmin menu groups.
#
# Each item names a route helper. While a resource still lives in ActiveAdmin its item points at
# the legacy_admin_* helper and is flagged `legacy: true`; porting a resource means switching the
# item to the new admin_* helper and dropping the flag.
class Admin::Menu
  Item = Struct.new(:label, :route, :legacy, :match, keyword_init: true) do
    def legacy? = legacy == true
  end
  Group = Struct.new(:label, :items, keyword_init: true)

  GROUPS = [
    Group.new(label: nil, items: [
      Item.new(label: 'Dashboard', route: :admin_root_path, match: :exact),
      Item.new(label: 'Reports', route: :admin_reports_path)
    ]),
    Group.new(label: 'Applicant Info', items: [
      Item.new(label: 'Applications', route: :admin_applications_path),
      Item.new(label: 'Applicant Details', route: :legacy_admin_applicant_details_path, legacy: true),
      Item.new(label: 'Course Assignments', route: :admin_course_assignments_path),
      Item.new(label: 'Session Selection', route: :admin_session_selections_path),
      Item.new(label: 'Session Assignments', route: :admin_session_assignments_path),
      Item.new(label: 'Course Preferences', route: :admin_course_preferences_path),
      Item.new(label: 'Applicant Activities', route: :admin_applicant_activities_path),
      Item.new(label: 'Financial Aid Requests', route: :legacy_admin_financial_aid_requests_path, legacy: true),
      Item.new(label: 'Payments', route: :legacy_admin_payments_path, legacy: true),
      Item.new(label: 'Recommendations', route: :admin_recommendations_path),
      Item.new(label: 'Recuploads', route: :admin_recuploads_path),
      Item.new(label: 'Rejections', route: :admin_rejections_path),
      Item.new(label: 'Travels', route: :admin_travels_path),
      Item.new(label: 'Payment Requests', route: :admin_payment_requests_path),
      Item.new(label: 'Nelnet Callback Logs', route: :admin_nelnet_callback_logs_path)
    ]),
    Group.new(label: 'Camp Setup', items: [
      Item.new(label: 'Camp Configurations', route: :admin_camp_configurations_path),
      Item.new(label: 'Session Configurations', route: :admin_session_configurations_path),
      Item.new(label: 'Activities', route: :admin_activities_path),
      Item.new(label: 'Courses', route: :admin_courses_path),
      Item.new(label: 'Campnotes', route: :admin_campnotes_path),
      Item.new(label: 'Demographics', route: :admin_demographics_path),
      Item.new(label: 'Gender Types', route: :admin_gender_types_path)
    ]),
    Group.new(label: 'Logins Info', items: [
      Item.new(label: 'Admins', route: :admin_admins_path),
      Item.new(label: 'Faculties', route: :admin_faculties_path),
      Item.new(label: 'Users', route: :admin_users_path),
      Item.new(label: 'Feedbacks', route: :admin_feedbacks_path)
    ]),
    Group.new(label: 'Admin', items: [
      Item.new(label: 'Comments', route: :admin_comments_path)
    ])
  ].freeze

  def self.groups = GROUPS
end
