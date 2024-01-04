ActiveAdmin.register Rejection do
  menu parent: 'Applicant Info', priority: 3

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :enrollment_id, :reason
  #
  # or
  #
  # permit_params do
  #   permitted = [:enrollment_id, :reason]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  filter :enrollment_id, as: :select, collection: Proc.new { Enrollment.current_camp_year_applications.map { |enrol| [enrol.display_name.downcase, enrol.id]}.sort }

  form do |f| # This is a formtastic form builder
    f.semantic_errors # shows errors on :base
    f.inputs do
      if params[:enrollment_id]
        li "<strong>Application: #{Enrollment.find(params[:enrollment_id]).display_name}</strong>".html_safe
        f.input :enrollment_id, input_html: {value: params[:enrollment_id]}, as: :hidden
      else
        f.input :enrollment_id, as: :select, collection: Enrollment.current_camp_year_applications.map { |enrol| [enrol.display_name.downcase, enrol.id]}.sort
      end
      f.input :reason
    end
    f.actions         # adds the 'Submit' and 'Cancel' button
  end

end
