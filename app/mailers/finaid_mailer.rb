class FinaidMailer < ApplicationMailer
  default from: 'University of Michigan MMSS High School Summer Program <mmss@umich.edu>'

  def fin_aid_awarded_email(finaid, balance_due)
    @url = ConstantData::HOST_URL
    @finaid = finaid
    @email = finaid.enrollment.user.email
    @balance_due = balance_due
    @student = ApplicantDetail.find_by(user_id: finaid.enrollment.user_id)
    mail(to: @email, subject: "MMSS - Financial Aid for #{@student.firstname} #{@student.lastname}")
  end

  def fin_aid_rejected_email(finaid, balance_due)
    @url = ConstantData::HOST_URL
    @email = finaid.enrollment.user.email
    @finaid = finaid
    @balance_due = balance_due
    @student = ApplicantDetail.find_by(user_id: finaid.enrollment.user_id)
    @camp_config = CampConfiguration.find_by(active: true)
    mail(to: @email, subject: "MMSS - Financial Aid for #{@student.firstname} #{@student.lastname}")
  end

  def fin_aid_request_email
    @enrollment = Enrollment.find_by(id: params[:enrollment])
    @student = ApplicantDetail.find_by(user_id: @enrollment.user_id)
    @url = "#{ConstantData::HOST_URL}" \
           "/financial_aids/new"
    mail(to: @enrollment.user.email,
         subject: "Financial Aid Request Form for #{@student.firstname} #{@student.lastname}")
  end
end
