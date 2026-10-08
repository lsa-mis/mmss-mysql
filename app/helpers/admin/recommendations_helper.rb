# frozen_string_literal: true

module Admin::RecommendationsHelper
  # Letter / upload-link status for a recommendation: received, waiting (link active), or the
  # link has expired / been cleared and needs to be resent.
  def admin_recommendation_link_badge(recommendation)
    if recommendation.recupload.present?
      link_to 'received', admin_recupload_path(recommendation.recupload), class: 'admin-badge-green'
    elsif recommendation.upload_link_active?
      tag.span('waiting', class: 'admin-badge-yellow')
    else
      tag.span('link expired', class: 'admin-badge-red')
    end
  end
end
