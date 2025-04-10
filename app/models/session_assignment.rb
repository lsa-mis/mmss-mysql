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
class SessionAssignment < ApplicationRecord
  belongs_to :enrollment
  belongs_to :camp_occurrence

  # Course assignments for this session
  has_many :course_assignments, through: :enrollment
  has_many :wait_list_assignments, -> { where(wait_list: true) },
           through: :enrollment,
           source: :course_assignments

  scope :current_year_session_assignments, -> { where(enrollment_id: Enrollment.current_camp_year_applications) }
  scope :accepted, -> { current_year_session_assignments.where(offer_status: 'accepted') }

  def accept_offer!(user)
    transaction do
      update!(offer_status: "accepted")
      CourseAssignment.handle_session_acceptance(self, user)
      enrollment.update_status_based_on_session_assignments!
    end
  end

  def decline_offer!(user)
    transaction do
      update!(offer_status: "declined")
      CourseAssignment.handle_session_declination(self, user)
      enrollment.update_status_based_on_session_assignments!
    end
  end

  private

  def self.ransackable_associations(auth_object = nil)
    ["camp_occurrence", "enrollment"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["camp_occurrence_id", "created_at", "enrollment_id", "id", "offer_status", "updated_at"]
  end
end
