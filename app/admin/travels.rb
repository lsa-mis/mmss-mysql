ActiveAdmin.register Travel do
  menu parent: 'Applicant Info', priority: 3

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

  filter :enrollment_applicant_detail_lastname_start, label: "Last Name (Starts with)"
  filter :enrollment_applicant_detail_firstname_start, label: "First Name (Starts with)"
  filter :arrival_session, label: "Session of Arrival", as: :select, collection: CampOccurrence.no_any_session.map { |s| s.description_with_month_and_day }
  filter :depart_session, label: "Session of Departure", as: :select, collection: CampOccurrence.no_any_session.map { |s| s.description_with_month_and_day }
  filter :arrival_date
  filter :depart_date, label: "Departure Date"
  filter :arrival_transport, as: :select
  filter :depart_transport, label: "Departure Transport", as: :select

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
      if travel.arrival_date.present?
        travel.arrival_date.strftime("%A, %d %b %Y")
      end
    end
    column :arrival_time do |travel|
      if travel.arrival_time.present?
        travel.arrival_time.strftime("%I:%M %p")
      end
    end
    column :depart_transport
    column :depart_carrier
    column :depart_route_num
    column :depart_date do |travel|
      if travel.depart_date.present?
        travel.depart_date.strftime("%A, %d %b %Y")
      end
    end
    column :depart_time do |travel|
      if travel.depart_time.present?
        travel.depart_time.strftime("%I:%M %p")
      end
    end
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
        if travel.arrival_date.present?
          travel.arrival_date.strftime("%A, %d %b %Y")
        end
      end
      row :arrival_time do |travel|
        if travel.arrival_time.present?
          travel.arrival_time.strftime("%I:%M %p")
        end
      end
      row :depart_transport
      row :depart_carrier
      row :depart_route_num
      row :depart_date do |travel|
        if travel.depart_date.present?
          travel.depart_date.strftime("%A, %d %b %Y")
        end
      end
      row :depart_time do |travel|
        if travel.depart_time.present?
          travel.depart_time.strftime("%I:%M %p")
        end
      end
      row :note
      row :created_at
      row :updated_at 
    end
  end

  form do |f| # This is a formtastic form builder
    f.semantic_errors *f.object.errors.keys # shows errors on :base
    f.inputs do
      f.input :enrollment_id, as: :select, collection: Enrollment.current_camp_year_applications.map { |enrol| [enrol.display_name.downcase, enrol.id]}.sort
      if f.object.new_record?
        f.input :arrival_session, as: :select, collection: CampOccurrence.active.no_any_session.map { |s| s.description_with_month_and_day }
      else
        f.input :arrival_session, as: :select, collection: Enrollment.find(Travel.find(params[:id]).enrollment_id).session_assignments.map { |s| s.camp_occurrence.description_with_month_and_day }
      end
      if f.object.new_record?
        f.input :depart_session, as: :select, collection: CampOccurrence.active.no_any_session.map { |s| s.description_with_month_and_day }
      else
        f.input :depart_session, as: :select, collection: Enrollment.find(Travel.find(params[:id]).enrollment_id).session_assignments.map { |s| s.camp_occurrence.description_with_month_and_day }
      end
      f.input :arrival_transport, as: :select, collection: transportation
      f.inputs :arrival_carrier
      f.inputs :arrival_route_num
      f.inputs :arrival_date 
      f.inputs :arrival_time 
      f.input :depart_transport, as: :select, collection: transportation
      f.inputs :depart_carrier
      f.inputs :depart_route_num
      f.inputs :depart_date
      f.inputs :depart_time
      f.inputs :note
    end
    f.actions
  end

  csv do
    column "Name" do |travel|
      travel.enrollment.applicant_detail.full_name
    end
    column "email" do |travel|
      travel.enrollment.user.email
    end
    column :arrival_session
    column :depart_session
    column :arrival_transport
    column :arrival_carrier
    column :arrival_route_num
    column :arrival_date do |travel|
      if travel.arrival_date.present?
        travel.arrival_date.strftime("%A, %d %b %Y")
      end
    end
    column :arrival_time do |travel|
      if travel.arrival_time.present?
        travel.arrival_time.strftime("%I:%M %p")
      end
    end
    column :depart_transport
    column :depart_carrier
    column :depart_route_num
    column :depart_date do |travel|
      if travel.depart_date.present?
        travel.depart_date.strftime("%A, %d %b %Y")
      end
    end
    column :depart_time do |travel|
      if travel.depart_time.present?
        travel.depart_time.strftime("%I:%M %p")
      end
    end
    column :note
  end

end
