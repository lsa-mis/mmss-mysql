# frozen_string_literal: true

module Admin::FormHelper
  # form_with using Admin::FormBuilder. Same arguments as form_with.
  def admin_form_with(**options, &block)
    form_with(**options, builder: Admin::FormBuilder, &block)
  end
end
