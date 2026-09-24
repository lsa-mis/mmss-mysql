# frozen_string_literal: true

# == Schema Information
#
# Table name: financial_aids
#
#  id                    :bigint           not null, primary key
#  enrollment_id         :bigint           not null
#  amount_cents          :integer          default(0)
#  source                :string(255)
#  note                  :text(65535)
#  status                :string(255)      default("pending")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  payments_deadline     :date
#  adjusted_gross_income :integer
#
# Indexes
#
#  index_financial_aids_on_enrollment_id  (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (enrollment_id => enrollments.id)
#
class FinancialAid < ApplicationRecord
  include ApplicantState
  include AdminCommentable

  after_commit :send_status_watch_email, if: :persisted?

  belongs_to :enrollment

  has_one_attached :taxform

  # Awards are never negative (a negative award would inflate the balance due). money-rails
  # already rejects non-numeric input; blank means "no amount yet" rather than an error, and the
  # raw input must satisfy Admin::MoneyInput (no exponents, third decimals or stray commas, which
  # Money would otherwise quietly reinterpret).
  monetize :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validate :amount_is_plain_money

  module BlankAmountIsZero
    def amount=(value)
      super(value.is_a?(String) && value.strip.empty? ? 0 : value)
    end
  end
  prepend BlankAmountIsZero

  validates :note, presence: :true
  validates :status, presence: true
  validates :adjusted_gross_income, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :source_required_when_awarded
  validate :acceptable_taxform
  validate :set_deadline

  scope :current_camp_requests, -> { where(enrollment_id: Enrollment.current_camp_year_applications) }


  private

  def amount_is_plain_money
    raw = instance_variable_get(:@amount_money_before_type_cast)
    return unless raw.is_a?(String)
    return if Admin::MoneyInput.valid?(raw)
    return if errors[:amount].any? # money-rails already reported it (not a number / negative)

    errors.add(:amount, 'must be a non-negative dollar amount with at most two decimals (e.g. 150.25)')
  end

  def source_required_when_awarded
    if status == 'awarded' && amount_cents > 0
      if source.blank?
        errors.add(:source, "is required when status is awarded and an amount is assigned")
      end
    end
  end

  def acceptable_taxform
    return unless taxform.attached?

    unless taxform.blob.byte_size <= 20.megabyte
      errors.add(:taxform, "is too big - file size cannot exceed 20Mbyte")
    end

    acceptable_types = ["image/png", "image/jpeg", "application/pdf"]
    unless acceptable_types.include?(taxform.content_type)
      errors.add(:taxform, "must be file type PDF, JPEG or PNG")
    end
  end

  def send_status_watch_email
    @current_enrollment = self.enrollment

    if self.status == 'awarded'
      FinaidMailer.fin_aid_awarded_email(self, balance_due).deliver_now
      @current_enrollment.auto_enroll_if_ready! if @current_enrollment.camp_doc_form_completed && balance_due == 0
    end
    if self.status == 'rejected'
      FinaidMailer.fin_aid_rejected_email(self, balance_due).deliver_now
    end
  end

  def set_deadline
    return if self.status == 'pending'

    if self.payments_deadline.blank?
      errors.add(:payments_deadline, "you need to set a date")
    end

    if self.amount_cents <= 0
      return if self.status == 'rejected'
      errors.add(:amount_cents, "you need to set an amount")
    end
  end
end
