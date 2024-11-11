ActiveAdmin.register User do
  menu parent: 'Logins Info', priority: 1
  config.filters = false

  # Allow email updates without requiring password
  permit_params :email, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :email
      f.input :password, required: false, 
              hint: "Leave blank if you don't want to change the password"
      f.input :password_confirmation, required: false
    end
    f.actions
  end

  # Custom update action to handle password changes
  controller do
    def update
      if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end
      super
    end
  end
end
