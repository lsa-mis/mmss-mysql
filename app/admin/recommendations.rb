# frozen_string_literal: true

ActiveAdmin.register Recommendation do
  menu parent: 'Applicant Info', priority: 3

  config.filters = false

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :enrollment_id, :email, :lastname, :firstname, :organization, :address1, :address2, :city, :state, :state_non_us, :postalcode, :country, :phone_number, :best_contact_time, :submitted_recommendation, :date_submitted
  #
  # or
  #
  # permit_params do
  #   permitted = [:enrollment_id, :email, :lastname, :firstname, :organization, :address1, :address2, :city, :state, :state_non_us, :postalcode, :country, :phone_number, :best_contact_time, :submitted_recommendation, :date_submitted]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :enrollment_id, as: :select, collection: Enrollment.current_camp_year_applications.map { |enrol| [enrol.display_name.downcase, enrol.id]}.sort
      f.input :email
      f.input :lastname
      f.input :firstname
      f.input :organization
      f.input :address1
      f.input :address2
      f.input :city
      f.input :state, as: :select, collection: us_states
      f.input :state_non_us
      f.input :postalcode
      f.input :country, include_blank: true
      f.input :phone_number
      f.input :best_contact_time
    end
    f.actions
  end

  index do
    selectable_column
    actions
    column :enrollment_id, sortable: :enrollment_id do |ei|
      link_to ei.enrollment.display_name, admin_application_path(ei.enrollment_id)
    end
    column :email
    column :lastname
    column :firstname
    column :organization
    column :address1
    column :address2
    column :city
    column :state
    column :state_non_us
    column :postalcode
    column :country
    column :phone_number
    column :best_contact_time
  end

  show do
    attributes_table do
      row "mail link", :id do |recid|
        link_to 'Resend request', send_request_email_path(recommendation_id: recid), { class: "btn" }
      end
      row :id
      row  :enrollment_id do |ei|
        link_to ei.enrollment.display_name, admin_application_path(ei.enrollment_id)
      end
      row :firstname
      row :lastname
      row :email
      row :organization
      row :address1
      row :address2
      row :city
      row :state
      row :state_non_us
      row :postalcode
      row :country
      row :phone_number
      row :best_contact_time
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

end
