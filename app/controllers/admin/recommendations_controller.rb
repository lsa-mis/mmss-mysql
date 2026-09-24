# frozen_string_literal: true

# Only the admin-only "resend request email" action for now; the Recommendations resource itself is
# ported in a later PR (index/show/edit are still served by ActiveAdmin at /legacy_admin).
class Admin::RecommendationsController < Admin::BaseController
  def send_request_email
    recommendation = Recommendation.find(params[:id])
    RecommendationMailer.with(recommendation: recommendation).request_email.deliver_now
    redirect_to legacy_admin_recommendation_path(recommendation), notice: 'Recommendation request was sent!', status: :see_other
  end
end
