ActiveAdmin.register ApplicantDetail do
  menu parent: 'Applicant Info', priority: 1

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :user_id, :firstname, :middlename, :lastname, :gender, :us_citizen, :demographic, :birthdate, :diet_restrictions, :shirt_size, :address1, :address2, :city, :state, :state_non_us, :postalcode, :country, :phone, :parentname, :parentaddress1, :parentaddress2, :parentcity, :parentstate, :parentstate_non_us, :parentzip, :parentcountry, :parentphone, :parentworkphone, :parentemail
  #
  actions :index, :show, :new, :create, :update, :edit

  form do |f| # This is a formtastic form builder
    f.semantic_errors # shows errors on :base
    # f.inputs           # builds an input field for every attribute
    f.inputs do
      f.input :user_id, as: :select, collection: User.all
      f.input :firstname
      f.input :middlename
      f.input :lastname
      f.input :gender, as: :select, collection: Gender.all
      f.input :us_citizen
      f.input :demographic, as: :select, collection: Demographic.all
      f.input :birthdate
      f.input :diet_restrictions
      # f.input :shirt_size
      f.input :address1
      f.input :address2
      f.input :city
      f.input :state, as: :select, collection: us_states
      f.input :state_non_us
      f.input :postalcode
      f.input :country
      f.input :phone
      f.input :parentname
      f.input :parentaddress1
      f.input :parentaddress2
      f.input :parentcity
      f.input :parentstate, as: :select, collection: us_states
      f.input :parentstate_non_us
      f.input :parentzip
      f.input :parentcountry, include_blank: true
      f.input :parentphone
      f.input :parentworkphone
      f.input :parentemail
    end
    f.actions 
  end

  filter :gender, as: :select, collection: Gender.all.map{|a| [a.name, a.id]}
  filter :demographic, as: :select, collection: Demographic.all.map{|a| [a.name, a.id]}
  filter :lastname, as: :select
  filter :us_citizen
  filter :birthdate
  filter :diet_restrictions
  filter :parentname

  index do 
    selectable_column
    actions
    column "Fullname" do |appdetail|
      appdetail.full_name
    end
    column('email') do |app|
      if app.user.enrollments.exists?
        div(title: 'Link to Application') do
          link_to app.applicant_email, admin_application_path(app.user.enrollments.last) 
        end
      else 
        app.applicant_email
      end
    end
    column :gender do |g|
      g.gender_name
    end
    column :us_citizen
    column :demographic do |d| 
        d.demographic_name
    end
    column :birthdate
    column :diet_restrictions
    # column :shirt_size
    column :address1
    column :address2
    column :city
    column :state
    column :state_non_us
    column :postalcode
    column :country
    column :phone
    column :created_at
    column :updated_at
  end

  show do
    panel "Applications" do
      table_for applicant_detail do
        column :firstname
        column :lastname
        column :gender do |g|
          g.gender_name
        end
        column('email') do |app| 
          if app.user.enrollments.exists?
            div(title: 'Link to Application') do
              link_to app.applicant_email, admin_application_path(app.user.enrollments.last) 
            end
          else
            app.applicant_email
          end
        end
      end
    end
    active_admin_comments
  end

  sidebar "Details", only: :show do
    attributes_table_for applicant_detail do
      row :id
      row :gender do |g|
        g.gender_name
      end
      row :birthdate
      row :diet_restrictions
      # row :shirt_size
      row :address1
      row :address2
      row :city
      row :state
      row :state_non_us
      row :postalcode
      row :country
      row :phone
      row :parentname
      row :parentphone
      row :parentworkphone
      row :parentemail
    end
  end
end
