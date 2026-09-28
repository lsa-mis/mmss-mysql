# frozen_string_literal: true

# Read-only audit trail of the redirects sent to Nelnet (PaymentRequest is written by the payment
# flow and matched to a Payment when the receipt callback arrives).
class Admin::PaymentRequestsController < Admin::BaseController
  SCOPES = [
    Admin::Scope.new(:all, label: 'All', default: true),
    Admin::Scope.new(:unmatched, label: 'Unmatched') { |relation| relation.where(payment_id: nil) }
  ].freeze

  SORTS = {
    id: 'payment_requests.id',
    user: 'users.email',
    order_number: 'payment_requests.order_number',
    amount: 'payment_requests.amount_cents',
    camp_year: 'payment_requests.camp_year',
    request_timestamp: 'payment_requests.request_timestamp',
    payment: 'payment_requests.payment_id',
    created_at: 'payment_requests.created_at'
  }.freeze

  def index
    @filter = Admin::PaymentRequestsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(PaymentRequest.left_joins(:user).preload(:user, :payment))
    @scope_counts = scope_counts(relation, SCOPES)
    relation = apply_scope(relation, SCOPES)
    relation = apply_sort(relation, allowed: SORTS, default: :created_at, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @payment_requests = paginate(relation) }
      format.csv { send_csv(csv_export, relation, filename: 'payment-requests') }
    end
  end

  def show
    @payment_request = PaymentRequest.includes(:user, :payment).find(params[:id])
  end

  private

  def csv_export
    view = helpers
    Admin::CsvExport.define do
      column :id
      column('User') { |request| request.user&.email }
      column :order_number
      column('Amount') { |request| view.admin_money_from_cents(request.amount_cents) }
      column :camp_year
      column('Request time') { |request| request.requested_at }
      column('Matched payment') { |request| request.payment_id }
      column :created_at
    end
  end
end
