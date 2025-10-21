ActiveAdmin.register FinancialAid, as: "Financial Aid Request" do
  menu parent: 'Applicant Info', priority: 3

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
   permit_params :enrollment_id, :amount, :source, :note, :status, :payments_deadline, :taxform
  #
  # or
  #
  # permit_params do
  #   permitted = [:enrollment_id, :amount_cents, :source, :awarded, :note, :status]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  filter :enrollment_id, as: :select, collection: Proc.new { Enrollment.current_camp_year_applications.map { |enrol| [enrol.display_name.downcase, enrol.id]}.sort }
  filter :status, as: :select
  filter :source, as: :select

  scope :current_camp_requests
  scope :all

  form do |f| # This is a formtastic form builder
    f.semantic_errors # shows errors on :base
    f.inputs do
      if params[:enrollment_id]
        li "<strong>Application: #{Enrollment.find(params[:enrollment_id]).display_name}</strong>".html_safe
        f.input :enrollment_id, input_html: {value: params[:enrollment_id]}, as: :hidden
      else
        f.input :enrollment_id, as: :select, collection: proc { Enrollment.current_camp_year_applications.map { |enrol| [enrol.display_name.downcase, enrol.id]}.sort }
      end
      f.input :amount
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

  csv do
    column "First Name" do |fa|
      fa.enrollment.applicant_detail.firstname
    end
    column "Last Name" do |fa|
      fa.enrollment.applicant_detail.lastname
    end
    column "email" do |fa|
      fa.enrollment.user.email
    end
    column "Residency Country" do |fa|
      fa.enrollment.applicant_detail.country
    end
    column "US Citizenship" do |fa|
      fa.enrollment.applicant_detail.us_citizen
    end
    column "Partner" do |fa|
      fa.enrollment.partner_program
    end
    column "Offer Status" do |fa|
      fa.enrollment.offer_status
    end
    column "FinAid Status" do |fa|
      fa.status
    end
    column "Funding Amount" do |fa|
      fa.amount
    end
    column "Funding Source" do |fa|
      fa.source
    end
    column :updated_at
  end

end
