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
class Payment < ApplicationRecord
  include ApplicantState

  after_commit :set_status, if: :persisted?

  validates :transaction_id, presence: true, uniqueness: true
  validates :total_amount, presence: true
  validates :transaction_date, presence: true

  belongs_to :user

  scope :current_camp_payments, -> { where('camp_year = ? ', CampConfiguration.active_camp_year) }
  scope :status1_current_camp_payments, -> { current_camp_payments.where('transaction_status = ?', '1') }

  private

  def set_status
    return unless transaction_status == '1'

    @current_enrollment = user.enrollments.current_camp_year_applications.last

    # Check if this is the first payment (when required)
    if @current_enrollment.application_fee_required && user.payments.current_camp_payments.where(transaction_status: 1).count == 1
      RegistrationMailer.app_complete_email(user).deliver_now
      if @current_enrollment.recommendation.present? && @current_enrollment.recommendation.recupload.present?
        @current_enrollment.update!(application_status: 'application complete',
                                    application_status_updated_on: Date.today)
      else
        @current_enrollment.update!(application_status: 'submitted', application_status_updated_on: Date.today)
      end
    elsif balance_due == 0 && @current_enrollment.camp_doc_form_completed
      @current_enrollment.update!(application_status: 'enrolled', application_status_updated_on: Date.today)
    end
  end

  def self.ransackable_associations(auth_object = nil)
    ['user']
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[account_type camp_year created_at id payer_identity result_code result_message timestamp
       total_amount transaction_date transaction_hash transaction_id transaction_status transaction_type updated_at user_account user_id]
  end
end
