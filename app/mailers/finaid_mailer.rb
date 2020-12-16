class FinaidMailer < ApplicationMailer
  
  default from: 'University of Michigan MMSS High School Summer Program <mmss@umich.edu>'

  def fin_aid_awarded_email(finaid, balance_due)
    @url = "https://lsa-math-mmss.miserver.it.umich.edu"
    @finaid = finaid
    @email = finaid.enrollment.user.email
    @balance_due = balance_due
    @student = ApplicantDetail.find_by(user_id: finaid.enrollment.user_id)
    mail(to: @email, subject: "MMSS - Financial Aid for #{@student.firstname} #{@student.lastname}")
  end

  def fin_aid_rejected_email(finaid, balance_due)
    @url = "https://lsa-math-mmss.miserver.it.umich.edu"
    @email = finaid.enrollment.user.email
    @finaid = finaid
    @balance_due = balance_due
    @student = ApplicantDetail.find_by(user_id: finaid.enrollment.user_id)
    mail(to: @email, subject: "MMSS - Financial Aid for #{@student.firstname} #{@student.lastname}")
  end

end
