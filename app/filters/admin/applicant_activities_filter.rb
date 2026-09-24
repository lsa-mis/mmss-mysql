# frozen_string_literal: true

class Admin::ApplicantActivitiesFilter < Admin::Filter
  select :enrollment_id, label: 'Enrollment', collection: -> { Admin::EnrollmentOptions.current_camp }
  select :activity_id, label: 'Activity', collection: -> { Admin::CampOptions.activities }
end
