ActiveAdmin.register CampConfiguration do
  menu parent: 'Camp Setup', priority: 1

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params  :camp_year, :application_open, :application_close, 
                  :priority, :application_materials_due, 
                  :camper_acceptance_due, :active, :offer_letter, 
                  :student_packet_url, :application_fee_cents, 
                  :reject_letter, :waitlist_letter
  #
  # or
  #
  # permit_params do
  #   permitted = [:camp_year, :application_open, :application_close, :priority, :application_materials_due, :camper_acceptance_due, :active]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end


  filter :application_open
  filter :application_close
  filter :priority
  filter :application_materials_due
  filter :camper_acceptance_due
  filter :active
  
  index do
    selectable_column
    actions
    column :camp_year
    column :application_open
    column :application_close
    column :priority
    column :application_materials_due
    column :camper_acceptance_due
    column :active
    column :student_packet_url
    column "Application Fee" do |af|
      humanized_money_with_symbol(af.application_fee)
    end
  end

  show do
    attributes_table do
    row :camp_year
    row :application_open
    row :application_close
    row :priority
    row :application_materials_due
    row :camper_acceptance_due
    row :active
    row "Offer Letter Text" do |item|
      item.offer_letter
    end
    row "Rejection Letter Text" do |item|
      item.reject_letter
    end
    row "Wait list Letter Text" do |item|
      item.waitlist_letter
    end
    row :student_packet_url
    row :application_fee_cents
    row :created_at
    row :updated_at 
    end
  end

end
