# frozen_string_literal: true

# Pagy-backed pagination for admin index pages.
#
#   @pagy, @applications = paginate(scope)
#
# `?page=` selects the page and `?limit=` lets admins pick a page size up to MAX_LIMIT.
module Admin::Paginatable
  extend ActiveSupport::Concern

  DEFAULT_LIMIT = 30
  MAX_LIMIT = 500

  included do
    include Pagy::Method
  end

  def paginate(scope, limit: DEFAULT_LIMIT)
    pagy(:offset, scope, limit: limit, client_limit: MAX_LIMIT)
  end
end
