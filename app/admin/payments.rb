ActiveAdmin.register Payment do
  menu parent: 'Applicant Info', priority: 3

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :user_id, :total_amount, :transaction_type, :transaction_status, :transaction_id, :transaction_date, :account_type, :result_code, :result_message, :user_account, :timestamp, :transaction_hash, :camp_year
  #
  # or
  #
  # permit_params do
  #   permitted = [:enrollment_id, :amount_cents, :source, :awarded, :note, :status]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  actions :index, :show, :new, :create, :update, :edit

  filter :user_id, as: :select, collection: User.all
  filter :account_type, as: :select
  filter :camp_year, as: :select
  filter :created_at



  form do |f| # This is a formtastic form builder
    f.semantic_errors # shows errors on :base
    f.inputs do
      if params[:enrollment_id]
        li "<strong>Application: #{Enrollment.find(params[:enrollment_id]).display_name}</strong>".html_safe
        f.input :user_id, input_html: {value: Enrollment.find(params[:enrollment_id]).user_id}, as: :hidden
      else
        f.input :user_id, as: :select, collection: Enrollment.current_camp_year_applications.map { |enrol| [enrol.last_name, enrol.user_id]}.sort 
      end
      f.input :total_amount
      li "Transaction Type #{f.object.transaction_type}" unless f.object.new_record?
      f.input :transaction_type, input_html: {value: "1"} unless f.object.persisted?
      li "Transaction Status #{f.object.transaction_status}" unless f.object.new_record?
      f.input :transaction_status, input_html: {value: "1"} unless f.object.persisted?
      f.input :transaction_id
      f.input :account_type
      f.input :result_message
      f.input :transaction_date, input_html: {value: "#{DateTime.now.strftime('%Y%m%d%H%M')}"}
      li "Camp Year #{f.object.camp_year}" unless f.object.new_record?
      f.input :camp_year, input_html: {value: current_camp_year} unless f.object.persisted?
    end
    f.actions         # adds the 'Submit' and 'Cancel' button
  end

  index do
    actions
    column "User" do |p|
      p.user.applicant_detail.full_name_and_email
    end
    column "Type" do |tt|
      tt.transaction_type
    end
    column "Status" do |ts|
      ts.transaction_status
    end
    column :transaction_id  
    column "Total Amount" do |p|
      humanized_money_with_symbol(p.total_amount.to_i / 100)
    end  
    column :transaction_date
    column :account_type    
    column :result_code     
    column :result_message  
    column :user_account    
    column :payer_identity  
    column :timestamp       
    column :camp_year
 
  end

end
