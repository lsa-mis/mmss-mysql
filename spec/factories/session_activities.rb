# frozen_string_literal: true

# == Schema Information
#
# Table name: session_activities
#
#  id                 :bigint           not null, primary key
#  enrollment_id      :bigint           not null
#  camp_occurrence_id :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_session_activities_on_camp_occurrence_id  (camp_occurrence_id)
#  index_session_activities_on_enrollment_id       (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (camp_occurrence_id => camp_occurrences.id)
#  fk_rails_...  (enrollment_id => enrollments.id)
#
FactoryBot.define do
  factory :session_activity do
    association :enrollment
    association :camp_occurrence
  end
end
