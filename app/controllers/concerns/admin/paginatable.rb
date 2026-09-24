# frozen_string_literal: true

# Pagy-backed pagination for admin index pages.
#
#   @pagy, @applications = paginate(scope)
#
# `?page=` selects the page and `?limit=` lets admins pick a page size (clamped to 1..MAX_LIMIT;
# anything unparsable falls back to the default).
module Admin::Paginatable
  extend ActiveSupport::Concern

  DEFAULT_LIMIT = 30
  MAX_LIMIT = 500

  included do
    include Pagy::Method
  end

  def paginate(scope, limit: DEFAULT_LIMIT)
    pagy(:offset, scope, limit: requested_limit(default: limit))
  end

  def requested_limit(default: DEFAULT_LIMIT)
    requested = params[:limit].to_s.to_i
    requested.positive? ? requested.clamp(1, MAX_LIMIT) : default
  end
end
