ActiveAdmin.register Faculty do
  menu parent: 'Logins Info', priority: 1

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :email, :encrypted_password, :reset_password_token, :reset_password_sent_at, :remember_created_at, :sign_in_count, :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip
  #
  # or
  #
  # permit_params do
  #   permitted = [:email, :encrypted_password, :reset_password_token, :reset_password_sent_at, :remember_created_at, :sign_in_count, :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  config.filters = false
  actions :index, :show

  index do
    selectable_column
    actions
    column :email
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
  end

  show do

    attributes_table do
      row :id
      row :email
      row :current_sign_in_at
      row :last_sign_in_at
      row :created_at
      row :updated_at 
    end

    panel "Courses for current camp" do
      table_for Course.current_camp.where(faculty_uniqname: faculty.email.split('@').first) do
        column("course") { |item| link_to(item.display_name, admin_course_path(item)) }
        column(:available_spaces)
        column(:status)
      end
    end
  end
  
end
