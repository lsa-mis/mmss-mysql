# frozen_string_literal: true

# Payments: Nelnet receipts recorded by PaymentsController#payment_receipt plus manual payments
# entered here. Financial records — there is no destroy, and the Nelnet-only fields (result code,
# user account, payer identity, timestamp, hash) are never writable from the form: a manual
# payment sets the applicant, the amount and the free-text transaction fields, and the type /
# status / date / camp year defaults that make it count as a successful payment.
#
# Saving a payment with transaction_status '1' runs Payment#set_status (after_commit), which may
# move the application to submitted / application complete or enroll it, exactly as a Nelnet
# receipt would.
class Admin::PaymentsController < Admin::BaseController
  before_action :set_payment, only: %i[show edit update]

  SORTS = {
    id: 'payments.id',
    user: 'applicant_details.lastname',
    transaction_type: 'payments.transaction_type',
    transaction_status: 'payments.transaction_status',
    transaction_id: 'payments.transaction_id',
    total_amount: 'CAST(payments.total_amount AS SIGNED)',
    transaction_date: 'payments.transaction_date',
    account_type: 'payments.account_type',
    result_code: 'payments.result_code',
    camp_year: 'payments.camp_year',
    created_at: 'payments.created_at'
  }.freeze

  # Defaults of a manual payment (ActiveAdmin pre-filled the same values): a successful (1)
  # web (1) transaction dated now, for the active camp.
  MANUAL_TRANSACTION_TYPE = '1'
  MANUAL_TRANSACTION_STATUS = '1'

  def index
    @filter = Admin::PaymentsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(base_relation)
    relation = apply_sort(relation, allowed: SORTS, default: :created_at, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @payments = paginate(relation) }
      format.csv { send_csv(csv_export, relation, filename: 'payments') }
    end
  end

  def show
    @applicant = @payment.user.enrollments.order(:id).last
  end

  # Entry point from the application's "Add Manual Payment" action: ?enrollment_id= prefills the
  # applicant (payments belong to the user) and the form shows the name instead of the select.
  def new
    @payment = Payment.new(manual_payment_defaults)
    @enrollment = Enrollment.find_by(id: params[:enrollment_id]) if params[:enrollment_id].present?
    @payment.user_id = @enrollment.user_id if @enrollment
  end

  def create
    @payment = Payment.new(payment_params_for_create)

    if @payment.save
      redirect_to admin_payment_path(@payment), notice: 'Payment was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @payment.update(payment_params_for_update)
      redirect_to admin_payment_path(@payment), notice: 'Payment was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_payment
    @payment = Payment.includes(user: :applicant_detail).find(params[:id])
  end

  def base_relation
    Payment.left_joins(user: :applicant_detail).preload(user: :applicant_detail)
  end

  def manual_payment_defaults
    {
      transaction_type: MANUAL_TRANSACTION_TYPE,
      transaction_status: MANUAL_TRANSACTION_STATUS,
      transaction_date: Time.current.strftime('%Y%m%d%H%M'),
      camp_year: CampConfiguration.active_camp_year
    }
  end

  # The payer, type, status, date and camp year are only settable when the payment is recorded
  # (the edit form shows them read-only). Re-homing a payment would detach it from the payer's
  # Nelnet payment request and re-run the status callback against the other applicant.
  def payment_params_for_create
    params.require(:payment).permit(:user_id, :total_amount_dollars, :transaction_id, :account_type, :result_message,
                                    :transaction_type, :transaction_status, :transaction_date, :camp_year)
  end

  def payment_params_for_update
    params.require(:payment).permit(:total_amount_dollars, :transaction_id, :account_type, :result_message)
  end

  # The ActiveAdmin resource had no custom CSV, so every column was exported; the Nelnet signature
  # (transaction_hash) is left out here.
  def csv_export
    view = helpers
    Admin::CsvExport.define do
      column :id
      column('User') { |payment| payment.user.applicant_detail&.full_name }
      column('email') { |payment| payment.user.email }
      column :transaction_type
      column :transaction_status
      column('Transaction status message') { |payment| view.transaction_status_message(payment.transaction_status) }
      column :transaction_id, header: 'Transaction id'
      column('Total amount') { |payment| Money.new(payment.total_amount.to_i) if payment.total_amount.present? }
      column :transaction_date
      column :account_type
      column :result_code
      column :result_message
      column :user_account
      column :payer_identity
      column :timestamp
      column :camp_year
      column :created_at
      column :updated_at
    end
  end
end
