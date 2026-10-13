# frozen_string_literal: true

# Builds the query parameters that admin index links (sort headers, scope tabs, CSV link, per-page
# form) carry over from the current request.
#
# Never feed `request.query_parameters` straight into `url_for`: keys such as `host`, `protocol`,
# `port` or `script_name` are interpreted as URL options and would turn the link into an
# off-site absolute URL. Only the known index parameters survive, and `only_path` is forced.
module Admin::UrlHelper
  INDEX_PARAMS = %w[q scope sort direction page limit].freeze

  # admin_index_params(sort: 'title', page: nil) => { q: {...}, scope: 'all', sort: 'title', only_path: true }
  def admin_index_params(overrides = {})
    kept = request.query_parameters.slice(*INDEX_PARAMS).transform_keys(&:to_sym)
    kept[:q] = kept[:q].to_unsafe_h if kept[:q].respond_to?(:to_unsafe_h)
    kept.merge(overrides.symbolize_keys).compact.merge(only_path: true)
  end

  # Path for the current index action with the given overrides applied.
  def admin_index_path(overrides = {})
    url_for(admin_index_params(overrides))
  end

  # Hidden fields that re-submit the carried-over index params from a GET form.
  def admin_index_hidden_fields(except: [])
    fields = admin_index_params.except(:only_path, *except.map(&:to_sym)).flat_map do |key, value|
      if value.is_a?(Hash)
        value.map { |sub_key, sub_value| hidden_field_tag("#{key}[#{sub_key}]", sub_value, id: nil) }
      else
        hidden_field_tag(key, value, id: nil)
      end
    end
    safe_join(fields)
  end
end
