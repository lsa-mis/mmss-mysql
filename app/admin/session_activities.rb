ActiveAdmin.register SessionActivity, as: 'Session Selection' do
  menu parent: 'Applicant Info', priority: 1
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :enrollment_id, :camp_occurrence_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:enrollment_id, :camp_occurrence_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  filter :enrollment_id, as: :select, collection: -> { Enrollment.current_camp_year_applications.map { |enrol| [enrol.last_name, enrol.id]}.sort}
  filter :camp_occurrence_id, label: "Session", as: :select, collection: CampOccurrence.active.no_any_session

  form do |f|
    f.inputs do
      f.input :enrollment_id, as: :select, collection: Enrollment.current_camp_year_applications
      f.input :camp_occurrence_id, label: "Session", as: :select, collection: CampOccurrence.active
    end
    f.actions
  end

  index do
    selectable_column
    actions
    column ("Enrollment") { |ss| link_to ss.enrollment.display_name, admin_application_path(ss.enrollment_id) }
    column ("Session") { |ss| ss.camp_occurrence }
    column :created_at
    column :updated_at
  end

  show do
    attributes_table do
      row ("Enrollment") { |ss| link_to ss.enrollment.user.email, admin_application_path(ss.enrollment_id) }
      row ("Session") { |ss| ss.camp_occurrence }
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
  
end
