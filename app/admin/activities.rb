ActiveAdmin.register Activity do
  menu parent: 'Camp Setup', priority: 3

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :camp_occurrence_id, :description, :cost, :date_occurs, :active
  #
  # or
  #
  # permit_params do
  #   permitted = [:camp_occurrence_id, :description, :cost_cents, :date_occurs, :active]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  batch_action :destroy, confirm: "Are you sure you want to delete the selected records? This action cannot be undone." do |ids|
    batch_action_collection.find(ids).each do |record|
      record.destroy
    end
    redirect_to collection_path, notice: "Successfully deleted selected records"
  end

  batch_action :toggle_active, confirm: "Are you sure you want to toggle the active status of the selected records?" do |ids|
    batch_action_collection.find(ids).each do |record|
      record.update(active: !record.active)
    end
    redirect_to collection_path, notice: "Successfully toggled active status for selected records"
  end

  filter :camp_occurrence_id, label: "Session", as: :select, collection: CampOccurrence.order(begin_date: :desc).no_any_session
  filter :description, as: :select
  filter :cost_cents
  filter :date_occurs
  filter :active

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :camp_occurrence, label: "Session", as: :select, collection: CampOccurrence.order(begin_date: :desc).no_any_session
      f.input :description, hint: 'For dormitory activities, please use "Residential Stay" (not "Dormitory") to ensure consistency across all environments'
      f.input :cost
      f.input :date_occurs
      f.input :active
    end
    f.actions
  end


  index do
    selectable_column
    actions
    column "Session" do |ca|
      ca.camp_occurrence
    end
    column :description
    column "Cost" do |af|
      humanized_money_with_symbol(af.cost)
    end
    column :date_occurs
    column :active
    column :created_at
    column :updated_at
  end

  show do
    attributes_table do
      row "Session" do |ca|
        ca.camp_occurrence
      end
      row :description
      row "Cost" do |af|
        humanized_money_with_symbol(af.cost)
      end
      row :date_occurs
      row :active
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end
