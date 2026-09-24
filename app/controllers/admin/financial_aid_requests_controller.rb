# frozen_string_literal: true

# Financial Aid Requests = FinancialAid records (the ActiveAdmin resource was registered
# `as: 'Financial Aid Request'`). The award logic lives in the model: saving with status
# `awarded`/`rejected` emails the applicant and may auto-enroll (FinancialAid#send_status_watch_email),
# and the validations require a deadline and an amount for anything but a pending request.
class Admin::FinancialAidRequestsController < Admin::BaseController
  before_action :set_financial_aid, only: %i[show edit update destroy]

  SCOPES = [
    Admin::Scope.new(:current_camp_requests, label: 'Current camp requests', default: true),
    Admin::Scope.new(:all, label: 'All')
  ].freeze

  SORTS = {
    id: 'financial_aids.id',
    enrollment: 'applicant_details.lastname',
    adjusted_gross_income: 'financial_aids.adjusted_gross_income',
    amount: 'financial_aids.amount_cents',
    source: 'financial_aids.source',
    status: 'financial_aids.status',
    payments_deadline: 'financial_aids.payments_deadline',
    created_at: 'financial_aids.created_at',
    updated_at: 'financial_aids.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  STATUS_OPTIONS = %w[pending awarded rejected].freeze

  def index
    @filter = Admin::FinancialAidRequestsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(base_relation)
    @scope_counts = scope_counts(relation, SCOPES)
    relation = apply_scope(relation, SCOPES)
    relation = apply_sort(relation, allowed: SORTS, default: :id, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @financial_aids = paginate(relation) }
      format.csv { send_csv(csv_export, relation, filename: 'financial_aid_requests') }
    end
  end

  def show
    @payment_state = PaymentState.new(@financial_aid.enrollment)
  end

  # Entry point from the application's "Add Financial Aid Request" action: ?enrollment_id=
  # prefills the applicant and the form shows the name instead of the select.
  def new
    @financial_aid = FinancialAid.new
    @financial_aid.enrollment = Enrollment.find_by(id: params[:enrollment_id]) if params[:enrollment_id].present?
  end

  def create
    @financial_aid = FinancialAid.new(financial_aid_params)

    if @financial_aid.save
      redirect_to admin_financial_aid_request_path(@financial_aid), notice: 'Financial aid request was successfully created.',
                                                                    status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @financial_aid.update(financial_aid_params)
      redirect_to admin_financial_aid_request_path(@financial_aid), notice: 'Financial aid request was successfully updated.',
                                                                    status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @financial_aid.destroy
    redirect_to admin_financial_aid_requests_path, notice: 'Financial aid request was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(FinancialAid.all, BATCH_ACTIONS, redirect_to_path: admin_financial_aid_requests_path)
  end

  private

  def set_financial_aid
    @financial_aid = FinancialAid.includes(enrollment: %i[user applicant_detail]).find(params[:id])
  end

  def base_relation
    FinancialAid.left_joins(enrollment: :applicant_detail)
                .preload(:taxform_attachment, enrollment: %i[user applicant_detail])
  end

  def financial_aid_params
    params.require(:financial_aid).permit(:enrollment_id, :amount, :source, :note, :status, :payments_deadline, :taxform,
                                          :adjusted_gross_income)
  end

  def csv_export
    view = helpers
    Admin::CsvExport.define do
      column('First Name') { |aid| aid.enrollment.applicant_detail&.firstname }
      column('Last Name') { |aid| aid.enrollment.applicant_detail&.lastname }
      column('email') { |aid| aid.enrollment.user.email }
      column('Residency Country') { |aid| aid.enrollment.applicant_detail&.country }
      column('US Citizenship') { |aid| aid.enrollment.applicant_detail&.us_citizen }
      column('Partner') { |aid| aid.enrollment.partner_program }
      column('Offer Status') { |aid| aid.enrollment.offer_status }
      column('FinAid Status') { |aid| aid.status }
      column('Funding Amount') { |aid| aid.amount }
      column('Funding Source') { |aid| aid.source }
      column('AGI') { |aid| view.admin_agi(aid.adjusted_gross_income) }
      column :updated_at
    end
  end
end
