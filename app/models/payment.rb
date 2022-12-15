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

  private

  def set_status
    return unless self.transaction_status == '1'

    @current_enrollment = self.user.enrollments.current_camp_year_applications.last
    if self.user.payments.current_camp_payments.where(transaction_status: 1).count == 1
      RegistrationMailer.app_complete_email(self.user).deliver_now
      @current_enrollment.update!(application_status: "submitted", application_status_updated_on: Date.today)
      if @current_enrollment.recommendation.present?
        if @current_enrollment.recommendation.recupload.present? 
          @current_enrollment.update!(application_status: "application complete", application_status_updated_on: Date.today)
        end
      end
    else 
      if balance_due == 0 && @current_enrollment.student_packet.attached?
        @current_enrollment.update!(application_status: "enrolled", application_status_updated_on: Date.today)
      end
    end
  end
end
