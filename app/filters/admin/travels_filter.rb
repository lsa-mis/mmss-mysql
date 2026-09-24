# frozen_string_literal: true

# The name filters rely on the controller's base relation joining enrollments -> applicant_details.
class Admin::TravelsFilter < Admin::Filter
  text :lastname, label: 'Last Name (Starts with)', match: :starts_with, column: 'applicant_details.lastname'
  text :firstname, label: 'First Name (Starts with)', match: :starts_with, column: 'applicant_details.firstname'
  select :arrival_session, label: 'Session of Arrival', collection: -> { distinct_values(:arrival_session) }
  select :depart_session, label: 'Session of Departure', collection: -> { distinct_values(:depart_session) }
  date_range :arrival_date
  date_range :depart_date, label: 'Departure Date'
  select :arrival_transport, collection: -> { distinct_values(:arrival_transport) }
  select :depart_transport, label: 'Departure Transport', collection: -> { distinct_values(:depart_transport) }

  def self.distinct_values(column)
    Travel.where.not(column => [nil, '']).distinct.order(column).pluck(column)
  end
end
