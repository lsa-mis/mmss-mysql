ActiveAdmin.register CourseAssignment do
  menu parent: 'Applicant Info', priority: 1

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :enrollment_id, :course_id

   filter :enrollment_id, as: :select, collection: -> { Enrollment.current_camp_year_applications.map { |enrol| [enrol.last_name, enrol.id]}.sort}
   filter :course_id, as: :select, collection: Course.where(camp_occurrence_id: CampOccurrence.active).order(camp_occurrence_id: :asc, title: :asc)

   form do |f|
    f.inputs do
      f.input :enrollment_id, as: :select, collection: Enrollment.current_camp_year_applications
      f.input :course_id, label: "Course", as: :select, collection: Course.where(camp_occurrence_id: CampOccurrence.active)
    end
    f.actions
  end

  index do
    selectable_column
    actions
    column ('Enrollment') { |ca| link_to ca.enrollment.display_name, admin_application_path(ca.enrollment_id) }
    column "Course" do |ca|
      ca.course
    end
    column :created_at
    column :updated_at
  end

  show do
    attributes_table do
      row ('Enrollment') { |ca| link_to ca.enrollment.display_name, admin_application_path(ca.enrollment_id) }
    row "Course" do |ca|
      ca.course
    end
    row :created_at
    row :updated_at
    end
    active_admin_comments
  end
 
end
