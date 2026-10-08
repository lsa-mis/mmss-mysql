# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id                 :bigint           not null, primary key
#  transaction_type   :string(255)
#  transaction_status :string(255)
#  transaction_id     :string(255)
#  total_amount       :string(255)
#  transaction_date   :string(255)
#  account_type       :string(255)
#  result_code        :string(255)
#  result_message     :string(255)
#  user_account       :string(255)
#  payer_identity     :string(255)
#  timestamp          :string(255)
#  transaction_hash   :string(255)
#  user_id            :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  camp_year          :integer
#
# Indexes
#
#  index_payments_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Payment < ApplicationRecord
  include ApplicantState

  after_commit :set_status, if: :persisted?

  validates :transaction_id, presence: true, uniqueness: true
  # total_amount is a whole number of cents stored as a string (what Nelnet sends and what the
  # balance arithmetic casts); anything else — negative, fractional, non-numeric — is refused.
  validates :total_amount, presence: true, unless: :invalid_dollar_input?
  validates :total_amount, format: { with: /\A\d+\z/, message: 'must be a whole number of cents' }, allow_blank: true
  validate :total_amount_dollars_is_money
  validates :transaction_type, presence: true
  validates :transaction_status, presence: true
  validates :transaction_date, presence: true
  validates :camp_year, presence: true

  belongs_to :user
  # A payment matched to a Nelnet payment request is part of the payment audit trail and cannot be
  # destroyed (`destroy` returns false with an error on :base). The admin exposes no destroy at all.
  has_one :payment_request, dependent: :restrict_with_error

  # Virtual attribute for dollar amounts in the admin manual-payment form. Only what
  # Admin::MoneyInput accepts ("150", "150.25", "$1,500.00") is stored; anything else leaves
  # total_amount untouched and fails validation instead of being coerced (`to_f` would have
  # turned "abc" into $0 and let "-5" through).
  def total_amount_dollars
    return @total_amount_dollars_input if invalid_dollar_input?
    return nil if total_amount.blank?

    (BigDecimal(total_amount) / 100).round(2).to_f
  end

  def total_amount_dollars=(value)
    @total_amount_dollars_input = value
    input = value.to_s.strip
    if input.empty?
      self.total_amount = nil
    elsif (cents = Admin::MoneyInput.parse_cents(input))
      self.total_amount = cents.to_s
    end
  end

  scope :current_camp_payments, -> { where('camp_year = ? ', CampConfiguration.active_camp_year) }
  scope :status1_current_camp_payments, -> { current_camp_payments.where('transaction_status = ?', '1') }

  private

  def invalid_dollar_input?
    input = @total_amount_dollars_input.to_s.strip
    input.present? && !Admin::MoneyInput.valid?(input)
  end

  def total_amount_dollars_is_money
    return unless invalid_dollar_input?

    errors.add(:total_amount_dollars, 'must be a non-negative dollar amount with at most two decimals (e.g. 150.25)')
  end

  def set_status
    return unless transaction_status == '1'

    @current_enrollment = user.enrollments.current_camp_year_applications.last
    return unless @current_enrollment

    # Check if this is the first payment (when required)
    first_successful_payment = user.payments.status1_current_camp_payments.count == 1

    if @current_enrollment.application_fee_required &&
       first_successful_payment &&
       @current_enrollment.can_transition_application_status?('submitted')
      RegistrationMailer.app_complete_email(user).deliver_now
      if @current_enrollment.recommendation.present? && @current_enrollment.recommendation.recupload.present?
        if @current_enrollment.can_transition_application_status?('application complete')
          @current_enrollment.transition_application_status!('application complete')
        end
      else
        @current_enrollment.transition_application_status!('submitted')
      end
    elsif balance_due == 0 && @current_enrollment.camp_doc_form_completed
      @current_enrollment.auto_enroll_if_ready!
    end
  end
end
