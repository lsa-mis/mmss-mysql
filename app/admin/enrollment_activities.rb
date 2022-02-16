ActiveAdmin.register EnrollmentActivity, as: "Applicant Activities" do
  menu parent: 'Applicant Info', priority: 3

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :enrollment_id, :activity_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:enrollment_id, :activity_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  filter :enrollment_id, as: :select, collection: -> { Enrollment.current_camp_year_applications.map { |enrol| [enrol.display_name, enrol.id]}.sort}
  filter :activity_id, as: :select, collection: Activity.where(camp_occurrence_id: CampOccurrence.active).order(camp_occurrence_id: :asc, description: :asc)


  form do |f|
    f.inputs do
      f.input :enrollment_id, as: :select, collection: Enrollment.current_camp_year_applications.map { |enrol| [enrol.display_name, enrol.id] }.sort
      f.input :activity_id, label: "Activity", as: :select, collection: Activity.where(camp_occurrence_id: CampOccurrence.active).order(camp_occurrence_id: :asc, description: :asc)
    end
    f.actions
  end
  
end
