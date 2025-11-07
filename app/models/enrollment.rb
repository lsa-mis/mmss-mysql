# frozen_string_literal: true

# == Schema Information
#
# Table name: enrollments
#
#  id                            :bigint           not null, primary key
#  user_id                       :bigint           not null
#  international                 :boolean          default(FALSE), not null
#  high_school_name              :string(255)      not null
#  high_school_address1          :string(255)      not null
#  high_school_address2          :string(255)
#  high_school_city              :string(255)      not null
#  high_school_state             :string(255)
#  high_school_non_us            :string(255)
#  high_school_postalcode        :string(255)
#  high_school_country           :string(255)      not null
#  year_in_school                :string(255)      not null
#  anticipated_graduation_year   :string(255)      not null
#  room_mate_request             :string(255)
#  personal_statement            :text(65535)      not null
#  notes                         :text(65535)
#  application_status            :string(255)
#  offer_status                  :string(255)
#  partner_program               :string(255)
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  campyear                      :integer
#  application_deadline          :date
#  application_status_updated_on :date
#  uniqname                      :string(255)
#  camp_doc_form_completed       :boolean          default(FALSE)
#  application_fee_required      :boolean          default(TRUE), not null
#
class Enrollment < ApplicationRecord
  before_update :if_camp_doc_form_completed
  before_update :if_application_status_changed
  before_update :set_application_deadline
  before_create :set_application_fee_required
  after_update :send_offer_letter
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

  validates :high_school_postalcode, presence: true
  validates :high_school_postalcode,
            length: { minimum: 1, maximum: 25, message: 'must be between 1 and 25 characters' },
            format: { with: /\A[a-zA-Z0-9\s\-]+\z/, message: 'can only contain letters, numbers, spaces, and dashes' }

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
  scope :withdrawn, -> { current_camp_year_applications.where("application_status = 'withdrawn'") }
  scope :application_complete, lambda {
    current_camp_year_applications.where("application_status = 'application complete'")
  }
  scope :application_complete_not_offered, -> { application_complete.where(offer_status: [nil, '']) }
  scope :no_recomendation, -> { current_camp_year_applications.where.missing(:recommendation) }
  scope :no_letter, lambda {
    current_camp_year_applications.where(id: Recommendation.where.missing(:recupload).pluck(:enrollment_id))
  }
  scope :no_payments, lambda {
    current_camp_year_applications.where.not(user_id: Payment.where(camp_year: CampConfiguration.active.last.camp_year).pluck(:user_id))
  }
  scope :no_student_packet, lambda {
    current_camp_year_applications.where.not(id: Enrollment.current_camp_year_applications.joins(:student_packet_attachment).pluck(:id))
  }
  scope :no_vaccine_record, lambda {
    enrolled.where.not(id: Enrollment.current_camp_year_applications.joins(:vaccine_record_attachment).pluck(:id))
  }
  scope :no_covid_test_record, lambda {
    enrolled.where.not(id: Enrollment.current_camp_year_applications.joins(:covid_test_record_attachment).pluck(:id))
  }
  scope :no_camp_doc_form, -> { current_camp_year_applications.where(camp_doc_form_completed: false) }

  def display_name
    "#{applicant_detail.full_name} - #{user.email}"
  end

  def last_name
    "#{applicant_detail.lastname} - #{user.email}"
  end

  def update_status_based_on_session_assignments!
    status_array = session_assignments.pluck(:offer_status)

    if all_session_assignments_declined?(status_array)
      update!(
        offer_status: 'declined',
        application_status: 'offer declined',
        application_status_updated_on: Date.current
      )
    elsif all_session_assignments_responded?(status_array)
      update!(
        offer_status: 'accepted',
        application_status: 'offer accepted',
        application_status_updated_on: Date.current
      )
    end
  end

  private

  def at_least_one_session_is_checked
    return unless session_registration_ids.empty?

    errors.add(:base, 'Select at least one session')
  end

  def at_least_one_course_is_checked
    return unless course_registration_ids.empty?

    errors.add(:base, 'Select at least one course')
  end

  def validate_transcript_presence
    errors.add(:transcript, 'should exist') unless transcript.attached?
  end

  def acceptable_transcript
    return unless transcript.attached?

    unless transcript.blob.byte_size <= 20.megabyte
      errors.add(:transcript, 'is too big - file size cannot exceed 20Mbyte')
    end

    acceptable_types = ['image/png', 'image/jpeg', 'application/pdf']
    return if acceptable_types.include?(transcript.content_type)

    errors.add(:transcript, 'must be file type PDF, JPEG or PNG')
  end

  def acceptable_student_packet
    return unless student_packet.attached?

    unless student_packet.blob.byte_size <= 20.megabyte
      errors.add(:student_packet, 'is too big - file size cannot exceed 20Mbyte')
    end

    acceptable_types = ['image/png', 'image/jpeg', 'application/pdf']
    return if acceptable_types.include?(student_packet.content_type)

    errors.add(:student_packet, 'must be file type PDF, JPEG or PNG')
  end

  def acceptable_image
    return unless covid_test_record.attached? || vaccine_record.attached?

    [covid_test_record, vaccine_record].compact.each do |image|
      next unless image.attached?

      errors.add(image.name, 'is too big') unless image.blob.byte_size <= 10.megabyte

      acceptable_types = ['image/png', 'image/jpeg', 'application/pdf']
      errors.add(image.name, 'incorrect file type') unless acceptable_types.include?(image.content_type)
    end
  end

  def if_camp_doc_form_completed
    payment = PaymentState.new(self)
    return unless camp_doc_form_completed && payment.balance_due.zero?

    self.application_status = 'enrolled'
  end

  def send_offer_letter
    return unless previous_changes[:offer_status]
    return unless offer_status == 'offered'

    OfferMailer.offer_email(user_id).deliver_now
  end

  def send_enroll_letter
    return unless previous_changes[:application_status]
    return unless application_status == 'enrolled'

    RegistrationMailer.app_enrolled_email(user).deliver_now
  end

  def send_rejected_letter
    return unless previous_changes[:application_status]
    return unless application_status == 'rejected'

    RejectedMailer.app_rejected_email(self).deliver_now
  end

  def send_waitlisted_letter
    return unless previous_changes[:application_status]
    return unless application_status == 'waitlisted'

    WaitlistedMailer.app_waitlisted_email(self).deliver_now
  end

  def set_application_deadline
    return unless session_assignments.present? && course_assignments.present?

    self.application_deadline = 30.days.from_now unless application_deadline.present?
  end

  def if_application_status_changed
    return unless application_status_changed?

    self.application_status_updated_on = Date.today
  end

  def set_application_fee_required
    active_camp = CampConfiguration.active.first
    self.application_fee_required = active_camp&.application_fee_required || false
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[
      anticipated_graduation_year application_deadline application_status
      application_status_updated_on campyear created_at high_school_address1
      high_school_address2 high_school_city high_school_country
      high_school_name high_school_non_us high_school_postalcode
      high_school_state id international notes offer_status partner_program
      personal_statement room_mate_request uniqname updated_at user_id
      year_in_school
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[
      applicant_detail course_assignments course_preferences course_registrations
      covid_test_record_attachment covid_test_record_blob enrollment_activities
      financial_aids recommendation registration_activities rejection
      session_activities session_assignments session_registrations
      student_packet_attachment student_packet_blob transcript_attachment
      transcript_blob travels user vaccine_record_attachment
      vaccine_record_blob
    ]
  end

  def all_session_assignments_declined?(status_array)
    status_array.all? { |status| status == 'declined' }
  end

  def all_session_assignments_responded?(status_array)
    status_array.all? { |status| ["accepted", "declined"].include?(status) }
  end
end
