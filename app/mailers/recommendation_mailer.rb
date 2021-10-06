class RecommendationMailer < ApplicationMailer

  default from: 'University of Michigan MMSS High School Summer Program <mmss-recommend@umich.edu>'

  def request_email
    @recommendation = params[:recommendation]
    @enrollment = Enrollment.find(@recommendation.enrollment_id)
    @student = ApplicantDetail.find_by(user_id: @enrollment.user_id)
    @hashval = "nGklDoc2egIkzFxr0U#{@recommendation.id}" # sha256_hash
    @url  = "#{ ConstantData::HOST_URL }/recuploads/new?id=#{ @student.id }&yr=#{ CampConfiguration.active_camp_year }&email=#{ @recommendation.email }&hash=#{ @hashval }"
    mail(to: @recommendation.email, subject: "Recommendation request for #{ @student.firstname } #{ @student.lastname }")
  end

end
