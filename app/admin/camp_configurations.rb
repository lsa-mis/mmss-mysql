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
                  :student_packet_url, :application_fee,
                  :reject_letter, :waitlist_letter

  controller do
    # Custom new method
    def new
      flash[:alert] = "Each letter's text and camp fee were copied from previous camp. Don't forget to edit them."
      @camp_configuration = CampConfiguration.last.dup
    end
  end


  filter :application_open
  filter :application_close
  filter :priority
  filter :application_materials_due
  filter :camper_acceptance_due
  filter :active
  
  # humanized_money_with_symbol(co.cost)
  form do |f| # This is a formtastic form builder
    f.semantic_errors *f.object.errors.keys # shows errors on :base
    f.inputs do
     f.input :camp_year
     f.input :application_open
     f.input :application_close
     f.input :priority
     f.input :application_materials_due
     f.input :camper_acceptance_due
     f.input :active
     f.input :offer_letter
     f.input :application_fee
     f.input :reject_letter
     f.input :waitlist_letter
     f.actions         # adds the 'Submit' and 'Cancel' button
    end
  end

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
    row "Application fee" do |cc|
      humanized_money_with_symbol(cc.application_fee)
    end
    row :created_at
    row :updated_at 
    end
  end

end
