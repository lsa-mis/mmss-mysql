# frozen_string_literal: true

class Admin::RejectionsFilter < Admin::Filter
  select :enrollment_id, label: 'Enrollment', collection: -> { Admin::EnrollmentOptions.current_camp }
  date_range :created_at, label: 'Rejected on'
end
