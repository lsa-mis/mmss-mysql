# frozen_string_literal: true

ActiveAdmin.register CampOccurrence, as: "Session Configurations" do
  menu parent: 'Camp Setup', priority: 2

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :camp_configuration_id, :description, :cost, :begin_date, :end_date, :active
  #
  # or
  #
  # permit_params do
  #   permitted = [:camp_configuration_id, :description, :begin_date, :end_date, :active]
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

  filter :camp_configuration
  filter :description, as: :select
  filter :begin_date
  filter :end_date
  filter :active

  form do |f| # This is a formtastic form builder
    f.semantic_errors *f.object.errors.keys # shows errors on :base
    f.inputs do
    #  f.input :camp_configuration_id
     f.input :camp_configuration, label: "Camp", as: :select, collection: CampConfiguration.order(camp_year: :desc)
     f.inputs :description
     f.inputs :begin_date
     f.inputs :end_date
     f.inputs :active
     f.inputs :cost
     f.actions         # adds the 'Submit' and 'Cancel' button
    end
  end

  index do
    selectable_column
    actions
    column "Camp Year" do |cy|
      cy.camp_configuration
    end
    column :description
    column "Cost" do |co|
      humanized_money_with_symbol(co.cost)
    end
    column :begin_date
    column :end_date
    column :active
    column :created_at
    column :updated_at
  end

  show do
    attributes_table do
      row "Camp Year" do |cy|
        cy.camp_configuration
      end
      row :description
      row "Cost" do |co|
        humanized_money_with_symbol(co.cost)
      end
      row :begin_date
      row :end_date
      row :active
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end
