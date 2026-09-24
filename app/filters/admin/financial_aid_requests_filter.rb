# frozen_string_literal: true

# Index filters for Admin::FinancialAidRequestsController (FinancialAid): applicant, status and
# funding source, as in ActiveAdmin.
class Admin::FinancialAidRequestsFilter < Admin::Filter
  select :enrollment_id, label: 'Enrollment', collection: -> { Admin::ApplicantOptions.enrollments }
  select :status, collection: -> { distinct_values(:status) }
  select :source, collection: -> { distinct_values(:source) }

  def self.distinct_values(column)
    FinancialAid.where.not(column => [nil, '']).distinct.order(column).pluck(column)
  end
end
