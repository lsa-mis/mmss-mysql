ActiveAdmin.register FinancialAid, as: "Financial Aid Request" do
  menu parent: 'Applicant Info', priority: 2

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :enrollment_id, :amount_cents, :source, :note, :status, :payments_deadline, :taxform
  #
  # or
  #
  # permit_params do
  #   permitted = [:enrollment_id, :amount_cents, :source, :awarded, :note, :status]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  filter :enrollment_id, as: :select, collection: Enrollment.current_camp_year_applications
  filter :status, as: :select 
  filter :source, as: :select

  form do |f| # This is a formtastic form builder
    f.semantic_errors # shows errors on :base
    f.inputs do
      if params[:enrollment_id]
        li "<strong>Application: #{Enrollment.find(params[:enrollment_id]).display_name}</strong>".html_safe
        f.input :enrollment_id, input_html: {value: params[:enrollment_id]}, as: :hidden
      else
        f.input :enrollment_id, as: :select, collection: Enrollment.current_camp_year_applications
      end
      f.input :amount_cents
      f.input :source
      f.input :note
      f.input :status, as: :select, collection: financial_aid_status
      f.input :payments_deadline
      f.input :taxform, as: :file
    end
    f.actions         # adds the 'Submit' and 'Cancel' button
  end

  index do
    selectable_column
    actions
    column :id, sortable: :id do |f|
      link_to f.id, admin_financial_aid_request_path(f)
    end
    column 'Enrollment' do |e|
      e.enrollment
    end
    column "Taxform" do |t|
      if t.taxform.attached?
        link_to t.taxform.filename, url_for(t.taxform)
      end
    end
    column "Amount" do |co|
      humanized_money_with_symbol(co.amount)
    end
    column :source
    column :note
    column :status
    column :payments_deadline
  end

  show do
    app_pay_status = PaymentState.new(financial_aid_request.enrollment)
    text_node "<strong>Balance Due: #{humanized_money_with_symbol(app_pay_status.balance_due / 100)}</strong>".html_safe
    attributes_table do
      row :id
      row "Application" do |ap|
        ap.enrollment
      end
      row :taxform do |tf|
        if tf.taxform.attached?
          link_to tf.taxform.filename, url_for(tf.taxform)
        end
      end
      row "Amount" do |co|
        humanized_money_with_symbol(co.amount)
      end
      row :source
      row :note
      row :status
      row :payments_deadline
    end
    active_admin_comments
  end

end
