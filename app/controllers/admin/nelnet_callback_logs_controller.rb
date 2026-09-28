# frozen_string_literal: true

# Read-only log of every request that hit the Nelnet payment_receipt callback.
class Admin::NelnetCallbackLogsController < Admin::BaseController
  SORTS = {
    id: 'nelnet_callback_logs.id',
    transaction_id: 'nelnet_callback_logs.transaction_id',
    order_number: 'nelnet_callback_logs.order_number',
    transaction_status: 'nelnet_callback_logs.transaction_status',
    transaction_total_amount: 'nelnet_callback_logs.transaction_total_amount',
    created_at: 'nelnet_callback_logs.created_at'
  }.freeze

  def index
    @filter = Admin::NelnetCallbackLogsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(NelnetCallbackLog.all)
    relation = apply_sort(relation, allowed: SORTS, default: :created_at, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @nelnet_callback_logs = paginate(relation) }
      format.csv { send_csv(csv_export, relation, filename: 'nelnet-callback-logs') }
    end
  end

  def show
    @nelnet_callback_log = NelnetCallbackLog.find(params[:id])
  end

  private

  def csv_export
    view = helpers
    Admin::CsvExport.define do
      column :id
      column :transaction_id, header: 'Transaction ID'
      column :order_number
      column :transaction_status
      column('Total amount') { |log| view.admin_money_from_cents(log.transaction_total_amount) if log.transaction_total_amount.present? }
      column :created_at
    end
  end
end
