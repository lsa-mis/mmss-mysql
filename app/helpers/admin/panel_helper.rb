# frozen_string_literal: true

# Cards, attribute lists and page chrome for admin pages.
module Admin::PanelHelper
  # <%= admin_panel 'Session Assignment', actions: link_to('Add', ...) do %> ... <% end %>
  def admin_panel(title = nil, actions: nil, html_class: nil, body_class: 'admin-card-body', &block)
    render 'admin/shared/panel', title: title, actions: actions, html_class: html_class, body_class: body_class,
                                 body: capture(&block)
  end

  # <%= admin_attributes @application do |a| %>
  #   <% a.row :offer_status, :application_status %>
  #   <% a.row 'Applicant' do |app| %><%= link_to ... %><% end %>
  # <% end %>
  def admin_attributes(record, &block)
    builder = Admin::AttributesBuilder.new
    capture { block.call(builder) }
    render 'admin/shared/attributes', record: record, rows: builder.rows
  end

  def admin_attribute_value(record, row)
    value = nil
    buffer = with_output_buffer { value = row.block.call(record) }
    buffer.presence || admin_format_value(value)
  end

  # Page title shown in the top bar and <title>; `actions` renders on the right of the header.
  def admin_page_title(title, subtitle: nil)
    content_for(:title, title)
    content_for(:subtitle, subtitle) if subtitle
  end

  def admin_page_actions(&block)
    content_for(:page_actions, &block)
  end

  # Small definition of a "stat" (label + value) for dashboard panels.
  def admin_stat(label, value)
    tag.div(class: 'flex items-baseline justify-between gap-4 py-1.5') do
      safe_join([tag.span(label, class: 'text-sm text-slate-600'), tag.span(value, class: 'text-sm font-semibold text-slate-900')])
    end
  end

  def admin_empty_state(message)
    tag.p(message, class: 'px-4 py-6 text-center text-sm text-slate-500')
  end
end
