ActiveAdmin.register SessionAssignment do
  menu parent: 'Applicant Info', priority: 1

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
 permit_params :enrollment_id, :camp_occurrence_id, :offer_status
  #
  # or
  #
  # permit_params do
  #   permitted = [:enrollment_id, :camp_occurrence_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  form do |f|
    f.inputs do
      f.input :enrollment_id, as: :select, collection: Enrollment.current_camp_year_applications
      f.input :camp_occurrence_id, label: "Session", as: :select, collection: CampOccurrence.active
      f.input :offer_status, as: :select, collection: ['accepted','declined']
    end
    f.actions
  end

  index do
    selectable_column
    actions
    column ('Enrollment') { |sa| link_to sa.enrollment.display_name, admin_application_path(sa.enrollment_id) }
    column "Session" do |sa|
      sa.camp_occurrence
    end
    column :created_at
    column :updated_at
    column :offer_status
  end

  show do
    attributes_table do
      row ('Enrollment') { |sa| link_to sa.enrollment.user.email, admin_application_path(sa.enrollment_id) }
    row "Session" do |sa|
      sa.camp_occurrence
    end
    row :created_at
    row :updated_at
    row :offer_status
    end
    active_admin_comments
  end


  filter :enrollment_id, as: :select, collection: -> { Enrollment.current_camp_year_applications.map { |enrol| [enrol.last_name, enrol.id]}.sort}
  filter :camp_occurrence_id, label: "Session", as: :select, collection: CampOccurrence.active.no_any_session
  filter :offer_status, as: :select
end

