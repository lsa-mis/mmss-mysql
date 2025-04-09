class RecommendationMailerPreview < ActionMailer::Preview
  def request_email
    recommendation = Recommendation.first
    RecommendationMailer.with(recommendation: recommendation).request_email
  end
end
