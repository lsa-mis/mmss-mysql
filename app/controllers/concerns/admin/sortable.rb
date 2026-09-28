# frozen_string_literal: true

# Column sorting for admin index pages driven by `?sort=<key>&direction=asc|desc`.
#
#   @applications = apply_sort(scope, allowed: SORTS, default: 'updated_at', default_direction: :desc)
#
# `allowed` maps the public sort keys to SQL order expressions (the caller is responsible for any
# joins those expressions need), so user input never reaches the ORDER BY clause directly.
module Admin::Sortable
  extend ActiveSupport::Concern

  included do
    helper_method :current_sort, :current_sort_direction
  end

  def apply_sort(scope, allowed:, default:, default_direction: :asc)
    key = params[:sort].to_s.presence_in(allowed.keys.map(&:to_s)) || default.to_s
    direction = if params[:sort].present? && key == params[:sort].to_s
                  params[:direction].to_s == 'desc' ? :desc : :asc
                else
                  default_direction
                end

    @current_sort = key
    @current_sort_direction = direction

    expression = allowed.fetch(key.to_sym) { allowed.fetch(key) }
    scope.reorder(Arel.sql("#{expression} #{direction.to_s.upcase}"))
  end

  def current_sort = @current_sort

  def current_sort_direction = @current_sort_direction || :asc
end
