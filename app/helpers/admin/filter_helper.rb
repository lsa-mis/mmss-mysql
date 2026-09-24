# frozen_string_literal: true

# Renders an Admin::Filter as a GET form (see app/views/admin/shared/_filter_form.html.erb).
#
#   <%= admin_filter_form @filter, url: admin_applications_path %>
module Admin::FilterHelper
  def admin_filter_form(filter, url:, title: 'Filters')
    render 'admin/shared/filter_form', filter: filter, url: url, title: title
  end

  def admin_filter_field(form, filter, field)
    key = Admin::Filter::PARAM_KEY
    id = "#{key}_#{field.param}"

    case field.type
    when :select
      form.select "#{key}[#{field.param}]", options_for_select(field.options, filter.value(field.param)),
                  { include_blank: 'Any' }, class: 'admin-input', id: id, **field.html
    when :boolean
      form.select "#{key}[#{field.param}]", options_for_select([%w[Yes true], %w[No false]], filter.value(field.param)),
                  { include_blank: 'Any' }, class: 'admin-input', id: id, **field.html
    when :number
      form.number_field "#{key}[#{field.param}]", value: filter.value(field.param), class: 'admin-input', id: id, **field.html
    when :date_range
      tag.div(class: 'mt-1 grid grid-cols-2 gap-2') do
        safe_join([
          form.date_field("#{key}[#{field.from_param}]", value: filter.value(field.from_param), class: 'admin-input mt-0',
                                                         id: "#{id}_from", aria: { label: "#{field.label} from" }),
          form.date_field("#{key}[#{field.to_param}]", value: filter.value(field.to_param), class: 'admin-input mt-0',
                                                       id: "#{id}_to", aria: { label: "#{field.label} to" })
        ])
      end
    else
      form.text_field "#{key}[#{field.param}]", value: filter.value(field.param), class: 'admin-input', id: id, **field.html
    end
  end

  def admin_filter_field_id(field)
    "#{Admin::Filter::PARAM_KEY}_#{field.param}#{'_from' if field.type == :date_range}"
  end
end
