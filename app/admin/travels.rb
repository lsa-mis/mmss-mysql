ActiveAdmin.register Travel do
  menu parent: 'Applicant Info', priority: 3

  config.filters = false
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :enrollment_id, :direction, :transport_needed, :date, :mode, :carrier, :route_num, :note
  #
  # or
  #
  # permit_params do
  #   permitted = [:enrollment_id, :direction, :transport_needed, :date, :mode, :carrier, :route_num, :note]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  if CampConfiguration.active.present?
    actions :all
  else
    actions :all, :except => [:new]
  end
  
end
