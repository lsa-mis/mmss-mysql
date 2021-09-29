ActiveAdmin.register CampOccurrence, as: "Session Configurations" do
  menu parent: 'Camp Setup', priority: 2

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :camp_configuration_id, :description, :cost_cents, :begin_date, :end_date, :active
  #
  # or
  #
  # permit_params do
  #   permitted = [:camp_configuration_id, :description, :begin_date, :end_date, :active]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  filter :camp_configuration
  filter :description, as: :select 
  filter :begin_date 
  filter :end_date 
  filter :active


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
