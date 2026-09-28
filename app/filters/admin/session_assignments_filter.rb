# frozen_string_literal: true

class Admin::SessionAssignmentsFilter < Admin::Filter
  select :enrollment_id, label: 'Enrollment', collection: -> { Admin::EnrollmentOptions.current_camp }
  select :camp_occurrence_id, label: 'Session', collection: -> { Admin::CampOptions.sessions }
  select :offer_status, collection: -> { SessionAssignment.where.not(offer_status: [nil, '']).distinct.order(:offer_status).pluck(:offer_status) }
end
