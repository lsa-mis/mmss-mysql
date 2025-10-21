# frozen_string_literal: true

class FinaidMailer < ApplicationMailer
  def fin_aid_awarded_email(finaid, balance_due)
    @url = root_url
    @finaid = finaid
    @email = finaid.enrollment.user.email
    @balance_due = balance_due
    @student = ApplicantDetail.find_by(user_id: finaid.enrollment.user_id)
    mail(to: @email, subject: 'University of Michigan - Michigan Math and Science Scholars: Financial Aid Awarded')
  end

  def fin_aid_rejected_email(finaid, balance_due)
    @url = root_url
    @email = finaid.enrollment.user.email
    @finaid = finaid
    @balance_due = balance_due
    @student = ApplicantDetail.find_by(user_id: finaid.enrollment.user_id)
    @camp_config = CampConfiguration.find_by(active: true)
    mail(to: @email, subject: 'University of Michigan - Michigan Math and Science Scholars: Financial Aid Rejected')
  end

  def fin_aid_request_email
    @enrollment = Enrollment.find_by(id: params[:enrollment])
    @student = ApplicantDetail.find_by(user_id: @enrollment.user_id)
    @url = new_financial_aid_url
    mail(to: @enrollment.user.email,
         subject: 'University of Michigan - Michigan Math and Science Scholars: Financial Aid Request Form')
  end
end
