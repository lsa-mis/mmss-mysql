ActiveAdmin.register Course do
  menu parent: 'Camp Setup', priority: 3

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :camp_occurrence_id, :title, :available_spaces, :status, :faculty_uniqname, :faculty_name
  #
  # or
  #
  # permit_params do
  #   permitted = [:camp_occurrence_id, :title, :available_spaces, :status]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  filter :camp_occurrence_id, label: "Session", as: :select, collection: CampOccurrence.order(begin_date: :desc).no_any_session
  filter :title
  filter :available_spaces, as: :select
  filter :status, as: :select

  scope :current_camp, :default => true, label: "Current Camp Courses"
  scope :all

  form do |f| # This is a formtastic form builder
    f.semantic_errors # shows errors on :base
    # f.inputs           # builds an input field for every attribute
    f.inputs do
      f.input :camp_occurrence, label: "Session", as: :select, collection: CampOccurrence.active.order(begin_date: :desc).no_any_session
      f.input :title
      f.input :available_spaces
      f.input :faculty_uniqname
      f.input :faculty_name
      f.input :status, as: :select, collection: course_status
    end
    f.actions         # adds the 'Submit' and 'Cancel' button
  end

  index do
    selectable_column
    actions
    column "Session" do |ss|
      ss.camp_occurrence
    end
    column :title
    column :available_spaces
    column "Open Spaces" do |op|
      op.available_spaces - CourseAssignment.number_of_assignments(op.id)
    end
    column :faculty_uniqname
    column :faculty_name
    column :status
    column :created_at
    column :updated_at

  end

  show do
    attributes_table do
      row "Session" do |ss|
        ss.camp_occurrence
      end
      row :title
      row :available_spaces
      row "Open Spaces" do |op|
        op.available_spaces - CourseAssignment.number_of_assignments(op.id)
      end
      row :faculty_uniqname
      row :faculty_name
      row :status
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

end
