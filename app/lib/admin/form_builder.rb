# frozen_string_literal: true

# Form builder used by every admin form (via Admin::FormHelper#admin_form_with). Wraps the
# standard Rails field helpers with the admin's Tailwind markup, labels, hints and inline errors.
#
#   <%= admin_form_with model: @course, url: admin_course_path(@course) do |f| %>
#     <%= f.errors_summary %>
#     <%= f.fieldset 'Course' do %>
#       <%= f.input :title %>
#       <%= f.input :status, as: :select, collection: course_status %>
#       <%= f.input :available_spaces, hint: 'Total seats including the wait list' %>
#       <%= f.input :active %>
#     <% end %>
#     <%= f.actions cancel: admin_courses_path %>
#   <% end %>
class Admin::FormBuilder < ActionView::Helpers::FormBuilder
  # Renders a labelled field. The input type is inferred from the model column unless `as:` is
  # given (:text, :textarea, :select, :boolean, :date, :datetime, :time, :number, :email,
  # :password, :file, :hidden). Remaining keyword arguments become HTML attributes of the input.
  def input(attribute, as: nil, label: nil, hint: nil, collection: nil, include_blank: nil,
            required: nil, wrapper_class: nil, **input_html)
    type = as || infer_type(attribute)
    return hidden_field(attribute, **input_html) if type == :hidden

    errors = error_messages(attribute)
    input_html[:class] = class_names(input_html[:class], input_class(type), 'admin-input-error' => errors.any?)
    input_html[:required] = true if required
    input_html[:'aria-invalid'] = true if errors.any?

    control = build_control(type, attribute, collection: collection, include_blank: include_blank, **input_html)

    @template.content_tag(:div, class: class_names('admin-field', wrapper_class)) do
      if type == :boolean
        @template.safe_join([
          @template.content_tag(:div, class: 'flex items-center gap-2') do
            @template.safe_join([control, label(attribute, label, class: 'text-sm font-medium text-slate-700')])
          end,
          hint_tag(hint), error_tag(errors)
        ])
      else
        @template.safe_join([
          label(attribute, label_text(attribute, label, required), class: 'admin-label'),
          control, hint_tag(hint), error_tag(errors)
        ])
      end
    end
  end

  # Card-style grouping of fields with a title.
  def fieldset(title = nil, description: nil, &block)
    @template.content_tag(:fieldset, class: 'admin-fieldset') do
      header = if title
                 @template.content_tag(:div, class: 'admin-card-header') do
                   @template.safe_join([
                     @template.content_tag(:legend, title, class: 'admin-card-title'),
                     (@template.content_tag(:p, description, class: 'text-xs text-slate-500') if description)
                   ].compact)
                 end
               end
      body = @template.content_tag(:div, class: 'admin-card-body grid gap-4', &block)
      @template.safe_join([header, body].compact)
    end
  end

  # Full-message list of validation errors, rendered above the form.
  def errors_summary
    return if object.nil? || object.errors.empty?

    @template.content_tag(:div, class: 'rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-800',
                                role: 'alert') do
      @template.safe_join([
        @template.content_tag(:p, "#{@template.pluralize(object.errors.count, 'error')} prevented this record from being saved:",
                              class: 'font-semibold'),
        @template.content_tag(:ul, class: 'mt-2 list-disc pl-5') do
          @template.safe_join(object.errors.full_messages.map { |message| @template.content_tag(:li, message) })
        end
      ])
    end
  end

  # Submit + cancel row. Additional buttons can be added with the block.
  def actions(submit_label = nil, cancel: nil, &block)
    submit_label ||= object&.persisted? ? "Update #{object_display_name}" : "Create #{object_display_name}"

    @template.content_tag(:div, class: 'flex flex-wrap items-center gap-3') do
      @template.safe_join([
        button(submit_label, class: 'admin-btn-primary', data: { turbo_submits_with: 'Saving…' }),
        (@template.capture(&block) if block),
        (@template.link_to('Cancel', cancel, class: 'admin-btn-secondary') if cancel)
      ].compact)
    end
  end

  private

  def object_display_name
    object.class.model_name.human
  end

  def infer_type(attribute)
    column = object.class.respond_to?(:columns_hash) && object.class.columns_hash[attribute.to_s]
    return :text unless column

    case column.type
    when :text then :textarea
    when :boolean then :boolean
    when :date then :date
    when :datetime then :datetime
    when :time then :time
    when :integer, :decimal, :float then :number
    else :text
    end
  end

  def input_class(type)
    case type
    when :boolean then 'admin-checkbox'
    when :file then 'mt-1 block w-full text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-slate-100 file:px-3 file:py-1.5 file:text-sm file:font-medium file:text-slate-700 hover:file:bg-slate-200'
    else 'admin-input'
    end
  end

  def build_control(type, attribute, collection:, include_blank:, **html)
    case type
    when :textarea then text_area(attribute, rows: 4, **html)
    when :select
      raise ArgumentError, "input #{attribute}: `as: :select` needs a `collection:`" if collection.nil?

      options = collection.respond_to?(:call) ? collection.call : collection
      select(attribute, options, { include_blank: include_blank.nil? ? true : include_blank }, **html)
    when :boolean then check_box(attribute, **html)
    when :date then date_field(attribute, **html)
    when :datetime then datetime_field(attribute, **html)
    when :time then time_field(attribute, **html)
    when :number then number_field(attribute, **html)
    when :email then email_field(attribute, **html)
    when :password then password_field(attribute, **html)
    when :file then file_field(attribute, **html)
    else text_field(attribute, **html)
    end
  end

  def label_text(attribute, label, required)
    text = label || object&.class&.human_attribute_name(attribute) || attribute.to_s.humanize
    required ? @template.safe_join([text, @template.content_tag(:span, '*', class: 'text-red-600')], ' ') : text
  end

  def error_messages(attribute)
    return [] unless object.respond_to?(:errors)

    object.errors[attribute]
  end

  def hint_tag(hint)
    @template.content_tag(:p, hint, class: 'admin-hint') if hint
  end

  def error_tag(errors)
    @template.content_tag(:p, errors.to_sentence, class: 'admin-error') if errors.any?
  end

  def class_names(...) = @template.class_names(...)
end
