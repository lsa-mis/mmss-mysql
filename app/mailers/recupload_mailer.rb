class RecuploadMailer < ApplicationMailer
    default from: 'University of Michigan MMSS High School Summer Program <mmss-recommend@umich.edu>'

  def received_email
    @recupload = params[:recupload]
    @recommendation = Recommendation.find(@recupload.recommendation_id)
    @student = @recommendation.enrollment.user.applicant_detail
    @url = ConstantData::HOST_URL
    mail(to: @recommendation.email, subject: "Recommendation for #{@student.firstname} #{@student.lastname}")
  end

  def applicant_received_email
    @url = ConstantData::HOST_URL
    @recupload = params[:recupload]
    @recommendation = Recommendation.find(@recupload.recommendation_id)
    @student_email = @recommendation.enrollment.user.email
    @student = @recommendation.enrollment.user.applicant_detail
    mail(to: @student_email, subject: "Recommendation received for #{@student.firstname} #{@student.lastname}")

  end

end
