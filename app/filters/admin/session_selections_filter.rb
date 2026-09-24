# frozen_string_literal: true

class Admin::SessionSelectionsFilter < Admin::Filter
  select :enrollment_id, label: 'Enrollment', collection: -> { Admin::EnrollmentOptions.current_camp }
  select :camp_occurrence_id, label: 'Session', collection: -> { Admin::CampOptions.sessions }
end
