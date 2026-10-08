class RecommendationMailerPreview < ActionMailer::Preview
  def request_email
    # Only recommendations still waiting for a letter carry an upload token.
    recommendation = Recommendation.where.not(upload_token: nil).first || Recommendation.first
    RecommendationMailer.with(recommendation: recommendation).request_email
  end
end
