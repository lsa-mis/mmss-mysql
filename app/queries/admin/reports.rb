# frozen_string_literal: true

# Registry of the admin CSV reports (Admin::Reports::Base subclasses), grouped as on the
# /admin/reports page. Lookups go through this list, so a URL segment can only ever select one of
# these classes.
module Admin::Reports
  GROUPS = {
    'Applications' => [
      Admin::Reports::AllCompleteApps,
      Admin::Reports::RegisteredButNotApplied,
      Admin::Reports::PendingCourseAssignmentsWithStudents,
      Admin::Reports::AcceptedCourseAssignmentsWithStudents,
      Admin::Reports::CompleteApplicationsWithCoursePreferences,
      Admin::Reports::WaitlistedApplicationsWithCoursePreferences,
      Admin::Reports::FinaidWithAppAndOfferStatus,
      Admin::Reports::CompleteAppsDemographicReport,
      Admin::Reports::OfferAcceptedWithBalanceDue
    ],
    'Enrolled students' => [
      Admin::Reports::EnrolledWithAddresses,
      Admin::Reports::EnrolledStudentDemographicReport,
      Admin::Reports::EnrolledEventsPerSession,
      Admin::Reports::EnrolledWithSessionsAndCourses,
      Admin::Reports::EnrolledWithSessionsAndTshirt,
      Admin::Reports::CourseAssignments,
      Admin::Reports::EnrolledWithAddressesAndMore,
      Admin::Reports::EnrolledForMoreThanOneSession,
      Admin::Reports::DormByGenderBySession
    ]
  }.freeze

  def self.all = GROUPS.values.flatten

  def self.keys = all.map(&:key)

  # The report class for a URL segment, or nil for anything not registered.
  def self.find(key) = all.find { |report| report.key == key.to_s }
end
