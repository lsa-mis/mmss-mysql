# == Schema Information
#
# Table name: enrollments
#
#  id                          :bigint           not null, primary key
#  user_id                     :bigint           not null
#  international               :boolean          default(FALSE), not null
#  high_school_name            :string           not null
#  high_school_address1        :string           not null
#  high_school_address2        :string
#  high_school_city            :string           not null
#  high_school_state           :string
#  high_school_non_us          :string
#  high_school_postalcode      :string
#  high_school_country         :string           not null
#  year_in_school              :string           not null
#  anticipated_graduation_year :string           not null
#  room_mate_request           :string
#  personal_statement          :text             not null
#  notes                       :text
#  application_status          :string
#  offer_status                :string
#  partner_program             :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  campyear                    :integer
#  application_deadline        :date
#  application_status_updated_on :date
#
class Enrollment < ApplicationRecord
  after_update :send_offer_letter
  before_update :set_application_deadline
  after_commit :send_enroll_letter, if: :persisted?
  after_commit :send_rejected_letter, if: :persisted?
  after_commit :send_waitlisted_letter, if: :persisted?

  belongs_to :user
  has_one :applicant_detail, through: :user

  has_many :enrollment_activities, dependent: :destroy
  has_many :registration_activities, through: :enrollment_activities, source: :activity

  has_many :session_activities, dependent: :destroy 
  has_many :session_registrations, through: :session_activities, source: :camp_occurrence

  has_many :session_assignments, dependent: :destroy
  accepts_nested_attributes_for :session_assignments, allow_destroy: true

  has_many :course_preferences, dependent: :destroy
  has_many :course_registrations, through: :course_preferences, source: :course
  accepts_nested_attributes_for :course_preferences, allow_destroy: true

  has_many :course_assignments, dependent: :destroy
  accepts_nested_attributes_for :course_assignments, allow_destroy: true

  has_many :financial_aids, dependent: :destroy
  has_many :travels, dependent: :destroy
  has_one :recommendation, dependent: :destroy

  has_one :rejection, dependent: :destroy

  has_one_attached :transcript
  has_one_attached :student_packet
  has_one_attached :vaccine_record
  has_one_attached :covid_test_record

  validates :high_school_name, presence: true
  validates :high_school_address1, presence: true
  validates :high_school_city, presence: true
  validates :high_school_country, presence: true
  validates :year_in_school, presence: true
  validates :anticipated_graduation_year, presence: true
  validates :personal_statement, presence: true
  validates :personal_statement, length: { minimum: 100 }

  validate :at_least_one_session_is_checked
  validate :at_least_one_course_is_checked

  validate :validate_transcript_presence
  validate :acceptable_transcript

  validate :acceptable_student_packet
  validate :acceptable_image

  validates :user_id, uniqueness: { scope: :campyear }

  scope :current_camp_year_applications, -> { where('campyear = ? ', CampConfiguration.active_camp_year) }
  scope :offered, -> { current_camp_year_applications.where("offer_status = 'offered'") }
  scope :accepted, -> { current_camp_year_applications.where("offer_status = 'accepted'") }
  scope :enrolled, -> { current_camp_year_applications.where("application_status = 'enrolled'") }
  scope :application_complete, -> { current_camp_year_applications.where("application_status = 'application complete'") }
  scope :application_complete_not_offered, -> { application_complete.where(offer_status: [nil, ""])}
  scope :no_recomendation, -> { current_camp_year_applications.where.missing(:recommendation) }
  scope :no_letter, -> { current_camp_year_applications.where(id: Recommendation.where.missing(:recupload).pluck(:enrollment_id)) }
  scope :no_payments, -> { current_camp_year_applications.where.not(user_id: Payment.where(camp_year: CampConfiguration.active.last.camp_year).pluck(:user_id)) }
  scope :no_student_packet, -> { current_camp_year_applications.where.not(id: Enrollment.current_camp_year_applications.joins(:student_packet_attachment).pluck(:id)) }
  scope :no_vaccine_record, -> { enrolled.where.not(id: Enrollment.current_camp_year_applications.joins(:vaccine_record_attachment).pluck(:id)) }
  scope :no_covid_test_record, -> { enrolled.where.not(id: Enrollment.current_camp_year_applications.joins(:covid_test_record_attachment).pluck(:id)) }

  def display_name
    "#{self.applicant_detail.full_name} - #{self.user.email}"
  end

  def last_name
    "#{self.applicant_detail.lastname} - #{self.user.email}"
  end

  private

  def at_least_one_session_is_checked
    if session_registration_ids.empty?
      errors.add(:base, "Select at least one session")
    end
  end

  def at_least_one_course_is_checked
    if course_registration_ids.empty?
      errors.add(:base, "Select at least one course")
    end
  end

  def validate_transcript_presence
    errors.add(:transcript, 'should exist') unless self.transcript.attached?
  end

  def acceptable_transcript
    return unless transcript.attached?

    unless transcript.blob.byte_size <= 5.megabyte
      errors.add(:transcript, "is too big - file size cannot exceed 5Mbyte")
    end

    acceptable_types = ["image/png", "image/jpeg", "application/pdf"]
    unless acceptable_types.include?(transcript.content_type)
      errors.add(:transcript, "must be file type PDF, JPEG or PNG")
    end
  end

  def acceptable_student_packet
    return unless student_packet.attached?

    unless student_packet.blob.byte_size <= 5.megabyte
      errors.add(:student_packet, "is too big - file size cannot exceed 5Mbyte")
    end

    acceptable_types = ["image/png", "image/jpeg", "application/pdf"]
    unless acceptable_types.include?(student_packet.content_type)
      errors.add(:student_packet, "must be file type PDF, JPEG or PNG")
    end
  end

  def acceptable_image
    return unless covid_test_record.attached? || vaccine_record.attached?

    [covid_test_record, vaccine_record].compact.each do |image|

      if image.attached?
        unless image.blob.byte_size <= 10.megabyte
          errors.add(image.name, "is too big")
        end

        acceptable_types = ["image/png", "image/jpeg", "application/pdf"]
        unless acceptable_types.include?(image.content_type)
          errors.add(image.name, "incorrect file type")
        end
      end
    end
  end

  def send_offer_letter
    if previous_changes[:offer_status]
      if self.offer_status == "offered"
        OfferMailer.offer_email(self.user_id).deliver_now
      end
    end
  end

  def send_enroll_letter
    if previous_changes[:application_status]
      if self.application_status == "enrolled"
        RegistrationMailer.app_enrolled_email(self.user).deliver_now
      end
    end
  end

  def send_rejected_letter
    if previous_changes[:application_status]
      if self.application_status == "rejected"
        RejectedMailer.app_rejected_email(self).deliver_now
      end
    end
  end

  def send_waitlisted_letter
    if previous_changes[:application_status]
      if self.application_status == "waitlisted"
        WaitlistedMailer.app_waitlisted_email(self).deliver_now
      end
    end
  end

  def set_application_deadline
    if self.session_assignments.present? && self.course_assignments.present?
      self.application_deadline = 30.days.from_now unless self.application_deadline.present?
    end
  end

end
