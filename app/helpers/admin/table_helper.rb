# frozen_string_literal: true

# Sortable, paginated index tables for the admin.
#
#   <%= admin_table @applications, pagy: @pagy, batch_actions: BATCH_ACTIONS, batch_url: batch_admin_applications_path,
#                   actions: ->(app) { [admin_application_path(app), edit_admin_application_path(app), admin_application_path(app)] } do |t| %>
#     <% t.column :updated_at, sort: true %>
#     <% t.column 'Applicant', sort: 'applicant' do |app| %>
#       <%= link_to app.display_name, admin_application_path(app) %>
#     <% end %>
#     <% t.column :offer_status %>
#   <% end %>
#
# `actions:` is either `true` (view/edit/delete links built from `url_for` of the record's
# admin route via `admin_record_paths`) or a lambda returning `[show, edit, delete]` paths
# (nil to omit a link). `batch_actions:` renders the checkbox column and batch action toolbar.
module Admin::TableHelper
  def admin_table(records, pagy: nil, actions: nil, batch_actions: nil, batch_url: nil, empty_message: 'No records found.', &block)
    builder = Admin::TableBuilder.new
    capture { block.call(builder) } if block

    render 'admin/shared/table', records: records, columns: builder.columns, pagy: pagy, actions: actions,
                                 batch_actions: batch_actions, batch_url: batch_url, empty_message: empty_message
  end

  # Renders one cell: ERB blocks write to the output buffer, lambdas return raw values that go
  # through admin_format_value.
  def admin_table_cell(record, column)
    value = nil
    buffer = with_output_buffer { value = column.block.call(record) }
    buffer.presence || admin_format_value(value)
  end

  # Column header that toggles ?sort=<key>&direction=... while keeping the other query params.
  def admin_sortable_header(label, sort_key)
    active = current_sort.to_s == sort_key.to_s
    next_direction = active && current_sort_direction.to_s == 'asc' ? 'desc' : 'asc'
    url = url_for(request.query_parameters.merge(sort: sort_key, direction: next_direction, page: nil))

    link_to url, class: class_names('group inline-flex items-center gap-1 hover:text-slate-900', 'text-um-blue' => active) do
      safe_join([label, admin_sort_indicator(active, current_sort_direction)])
    end
  end

  def admin_sort_indicator(active, direction)
    glyph = active ? (direction.to_s == 'asc' ? '▲' : '▼') : '↕'
    tag.span(glyph, class: class_names('text-[10px]', active ? 'text-um-blue' : 'text-slate-300 group-hover:text-slate-500'),
                    aria: { hidden: true })
  end

  # View / Edit / Delete links for a row.
  def admin_row_actions(show_path, edit_path, delete_path, confirm: 'Are you sure you want to delete this record?')
    links = []
    links << link_to('View', show_path, class: 'admin-btn-link') if show_path
    links << link_to('Edit', edit_path, class: 'admin-btn-link') if edit_path
    if delete_path
      links << button_to('Delete', delete_path, method: :delete, form: { data: { turbo_confirm: confirm } },
                                                class: 'admin-btn-link text-red-700 hover:text-red-900')
    end
    safe_join(links, tag.span('·', class: 'text-slate-300 mx-1'))
  end

  # Pagination nav + "Showing x–y of z" summary built from a Pagy::Offset.
  def admin_pagination(pagy)
    render 'admin/shared/pagination', pagy: pagy
  end

  # Scope tabs (see Admin::Scopable). `counts` comes from `scope_counts`.
  def admin_scope_tabs(scopes, counts: {})
    render 'admin/shared/scope_tabs', scopes: scopes, counts: counts
  end

  def admin_scope_path(scope)
    url_for(request.query_parameters.merge(scope: scope.param, page: nil))
  end

  # Link to the CSV export of the current (filtered, scoped, sorted) index.
  def admin_csv_link(text = 'Download CSV')
    link_to text, url_for(request.query_parameters.merge(format: :csv, page: nil, limit: nil)),
            class: 'admin-btn-secondary', data: { turbo: false }
  end
end
