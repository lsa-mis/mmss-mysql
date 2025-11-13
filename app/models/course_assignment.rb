# frozen_string_literal: true

# == Schema Information
#
# Table name: course_assignments
#
#  id            :bigint           not null, primary key
#  enrollment_id :bigint           not null
#  course_id     :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  wait_list     :boolean          default(FALSE)
#
class CourseAssignment < ApplicationRecord
  belongs_to :enrollment
  belongs_to :course

  validates :enrollment_id, presence: true
  validates :course_id, presence: true

  scope :for_session, ->(session_id) { joins(:course).where(courses: { camp_occurrence_id: session_id }) }
  scope :wait_list, -> { where(wait_list: true) }
  scope :confirmed, -> { where(wait_list: false) }

  def self.find_for_session(session_id, enrollment_id, wait_list: false)
    for_session(session_id)
      .where(enrollment_id: enrollment_id, wait_list: wait_list)
      .first
  end

  def self.find_wait_list_for_session(session_id, enrollment_id)
    for_session(session_id)
      .wait_list
      .where(enrollment_id: enrollment_id)
      .first
  end

  def self.remove_for_session(session_id, enrollment_id)
    transaction do
      confirmed_assignment = find_for_session(session_id, enrollment_id)
      wait_list_assignment = find_wait_list_for_session(session_id, enrollment_id)

      confirmed_assignment&.destroy
      wait_list_assignment&.destroy
    end
  end

  def self.handle_session_acceptance(session_assignment, user)
    course_assignment = find_for_session(session_assignment.camp_occurrence_id, session_assignment.enrollment_id)
    OfferMailer.offer_accepted_email(user.id, session_assignment, course_assignment).deliver_now
  end

  def self.handle_session_declination(session_assignment, user)
    course_assignment = find_for_session(session_assignment.camp_occurrence_id, session_assignment.enrollment_id)
    remove_for_session(session_assignment.camp_occurrence_id, session_assignment.enrollment_id)
    OfferMailer.offer_declined_email(user.id, session_assignment, course_assignment).deliver_now
  end

  scope :number_of_assignments, ->(course_id="") {where(course_id: course_id, wait_list: false).size}
  scope :wait_list_number, -> (course_id="") { where(course_id: course_id, wait_list: true).size }

  def self.ransackable_associations(auth_object = nil)
    ["course", "enrollment"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["course_id", "created_at", "enrollment_id", "id", "updated_at", "wait_list"]
  end

end
