ActiveAdmin.register Demographic do
  menu parent: 'Camp Setup'

  config.filters = false

  permit_params :name, :description, :protected

  actions :all

  index do
    selectable_column
    column :name
    column :description
    column :protected
    column :created_at
    column :updated_at
    actions defaults: false do |demographic|
      if demographic.protected?
        item 'View', admin_demographic_path(demographic), class: 'member_link'
      else
        item 'View', admin_demographic_path(demographic), class: 'member_link'
        item 'Edit', edit_admin_demographic_path(demographic), class: 'member_link'
        item 'Delete', admin_demographic_path(demographic), 
             method: :delete, 
             class: 'member_link',
             data: { confirm: 'Are you sure?' }
      end
    end
  end

  form do |f|
    if f.object.protected?
      panel "Protected Record" do
        para "This demographic record is protected and cannot be modified."
      end
      # Display read-only information
      attributes_table_for f.object do
        row :name
        row :description
        row :protected
      end
    else
      f.inputs do
        f.input :name
        f.input :description
        f.input :protected
      end
      f.actions
    end
  end

  controller do
    def scoped_collection
      # Show all records instead of just modifiable ones
      Demographic.all
    end

    def update
      # Prevent updates to protected records
      if resource.protected?
        flash[:error] = "Cannot modify protected demographic records"
        redirect_to admin_demographic_path(resource)
      else
        super
      end
    end

    def destroy
      # Prevent deletion of protected records
      if resource.protected?
        flash[:error] = "Cannot delete protected demographic records"
        redirect_to admin_demographic_path(resource)
      else
        super
      end
    end
  end
end
