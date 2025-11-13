# frozen_string_literal: true

# == Schema Information
#
# Table name: session_assignments
#
#  id                 :bigint           not null, primary key
#  enrollment_id      :bigint           not null
#  camp_occurrence_id :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  offer_status       :string(255)
#
# Indexes
#
#  index_session_assignments_on_camp_occurrence_id  (camp_occurrence_id)
#  index_session_assignments_on_enrollment_id       (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (camp_occurrence_id => camp_occurrences.id)
#  fk_rails_...  (enrollment_id => enrollments.id)
#
FactoryBot.define do
  factory :session_assignment do
    association :enrollment
    association :camp_occurrence

    offer_status { nil }

    trait :accepted do
      offer_status { 'accepted' }
    end

    trait :declined do
      offer_status { 'declined' }
    end

    trait :pending do
      offer_status { nil }
    end
  end
end
