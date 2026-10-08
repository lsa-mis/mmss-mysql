class RecommendationMailerPreview < ActionMailer::Preview
  def request_email
    # request_email only renders for an active link: a recommendation with an unexpired token and
    # no letter yet (see Recommendation#upload_link_active?).
    recommendation = Recommendation.where.missing(:recupload)
                                   .where.not(upload_token: nil)
                                   .where(upload_token_expires_at: Time.current..)
                                   .order(:created_at)
                                   .first
    raise 'No recommendation with an active upload link to preview; create one or use "Resend request" in the admin.' if recommendation.nil?

    RecommendationMailer.with(recommendation: recommendation).request_email
  end
end
