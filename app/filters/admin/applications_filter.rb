# frozen_string_literal: true

# Index filters for Admin::ApplicationsController (Enrollment). The controller's base relation
# left-joins applicant_details, which the name filters and the applicant sort rely on.
class Admin::ApplicationsFilter < Admin::Filter
  text :lastname, label: 'Last Name (Starts with)', match: :starts_with, column: 'applicant_details.lastname'
  text :firstname, label: 'First Name (Starts with)', match: :starts_with, column: 'applicant_details.firstname'
  boolean :international
  select :year_in_school, collection: -> { distinct_values(Enrollment.current_camp_year_applications, :year_in_school) }
  select :anticipated_graduation_year, collection: -> { distinct_values(Enrollment, :anticipated_graduation_year) }
  select :application_status, collection: -> { distinct_values(Enrollment, :application_status) }
  select :offer_status, collection: -> { distinct_values(Enrollment, :offer_status) }
  date_range :application_deadline
  select :campyear, label: 'Camp year', collection: -> { distinct_values(Enrollment, :campyear, order: :desc) }

  def self.distinct_values(relation, column, order: :asc)
    relation.where.not(column => [nil, '']).distinct.order(column => order).pluck(column)
  end
end
