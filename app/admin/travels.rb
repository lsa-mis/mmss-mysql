ActiveAdmin.register Travel do
  menu parent: 'Applicant Info', priority: 3

  config.filters = false
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :enrollment_id, :arrival_session, :depart_session, 
                  :arrival_transport, :arrival_carrier, :arrival_route_num, :arrival_date, :arrival_time, 
                  :depart_transport, :depart_carrier, :depart_route_num, :depart_date, :depart_time, :note
  #
  # or
  #
  # permit_params do
  #   permitted = [:enrollment_id, :direction, :transport_needed, :date, :mode, :carrier, :route_num, :note]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  index do
    selectable_column
    actions
    column "Applicant" do |travel| 
      link_to travel.enrollment.display_name, admin_application_path(travel.enrollment) 
    end
    column :arrival_session
    column :depart_session
    column :arrival_transport
    column :arrival_carrier
    column :arrival_route_num
    column :arrival_date do |travel|
      travel.arrival_date.strftime("%A, %d %b %Y")
    end
    column :arrival_time do |travel|
      travel.arrival_time.strftime("%I:%M %p")
    end
    column :depart_transport
    column :depart_carrier
    column :depart_route_num
    column :depart_date
    column :depart_time
    column :note
  end

  show do
    attributes_table do
      row "Applicant" do |travel|
        link_to travel.enrollment.display_name, admin_application_path(travel.enrollment) 
      end
      row :arrival_session
      row :depart_session
      row :arrival_transport
      row :arrival_carrier
      row :arrival_route_num
      row :arrival_date do |travel|
        travel.arrival_date.strftime("%A, %d %b %Y")
      end
      row :arrival_time do |travel|
        travel.arrival_time.strftime("%I:%M %p")
      end
      row :depart_transport
      row :depart_carrier
      row :depart_route_num
      row :depart_date
      row :depart_time
      row :note
      row :created_at
      row :updated_at 
    end
  end

  form do |f| # This is a formtastic form builder
    f.semantic_errors *f.object.errors.keys # shows errors on :base
    f.inputs do
      f.input :enrollment_id, as: :select, collection: Enrollment.current_camp_year_applications.map { |enrol| [enrol.display_name.downcase, enrol.id]}.sort
      f.inputs :arrival_session
      f.inputs :depart_session
      f.inputs :arrival_transport
      f.inputs :arrival_carrier
      f.inputs :arrival_route_num
      f.inputs :arrival_date 
      f.inputs :arrival_time 
      f.inputs :depart_transport
      f.inputs :depart_carrier
      f.inputs :depart_route_num
      f.inputs :depart_date
      f.inputs :depart_time
      f.inputs :note
    end
    f.actions
  end

end
