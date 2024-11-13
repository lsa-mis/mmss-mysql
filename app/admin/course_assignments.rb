ActiveAdmin.register CourseAssignment do
  menu parent: 'Applicant Info', priority: 1

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :enrollment_id, :course_id, :wait_list

  filter :enrollment_id, as: :select, collection: lambda {
    Enrollment.current_camp_year_applications.map do |enrol|
      [enrol.display_name.downcase, enrol.id]
    end.sort
  }
  filter :course_id, as: :select, collection: lambda {
    Course.where(camp_occurrence_id: CampOccurrence.active).order(camp_occurrence_id: :asc, title: :asc)
  }

  form do |f|
    f.inputs do
      f.input :enrollment_id, as: :select, collection: Enrollment.current_camp_year_applications.map { |enrol|
        [enrol.display_name.downcase, enrol.id]
      }.sort
      f.input :course_id, label: 'Course', as: :select, collection: Course.where(camp_occurrence_id: CampOccurrence.active)
    end
    f.inputs :wait_list
    f.actions
  end

  index do
    selectable_column
    actions
    column('Enrollment') { |ca| link_to ca.enrollment.display_name, admin_application_path(ca.enrollment_id) }
    column 'Course', &:course
    column :wait_list
    column :created_at
    column :updated_at
  end

  show do
    attributes_table do
      row('Enrollment') { |ca| link_to ca.enrollment.display_name, admin_application_path(ca.enrollment_id) }
      row 'Course', &:course
      row :wait_list
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  csv do
    column 'Name' do |ca|
      ca.enrollment.applicant_detail.full_name
    end
    column 'email' do |ca|
      ca.enrollment.user.email
    end
    column 'Course' do |ca|
      ca.course.title
    end
    column 'Session' do |ca|
      ca.course.camp_occurrence.display_name
    end
  end
end
