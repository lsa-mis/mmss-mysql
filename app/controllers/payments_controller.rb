# frozen_string_literal: true

require 'digest'
require 'time'

class PaymentsController < ApplicationController
  include ApplicantState

  skip_before_action :verify_authenticity_token, only: [:payment_receipt]
  devise_group :logged_in, contains: [:user, :admin]
  prepend_before_action :log_nelnet_callback, only: [:payment_receipt]
  before_action :authenticate_logged_in!
  before_action :authenticate_admin!, only: [:index, :destroy]

  before_action :set_current_enrollment

  def index
    redirect_to root_url
  end

  def payment_receipt
    if Payment.pluck(:transaction_id).include?(params['transactionId'])
      link_payment_request_to_receipt(Payment.find_by(transaction_id: params['transactionId']))
      redirect_to all_payments_path
    else
      payment = Payment.create(
        transaction_type: params['transactionType'],
        transaction_status: params['transactionStatus'],
        transaction_id: params['transactionId'],
        total_amount: params['transactionTotalAmount'],
        transaction_date: params['transactionDate'],
        account_type: params['transactionAcountType'],
        result_code: params['transactionResultCode'],
        result_message: params['transactionResultMessage'],
        user_account: params['orderNumber'],
        payer_identity: current_user.email,
        timestamp: params['timestamp'],
        transaction_hash: params['hash'],
        user_id: current_user.id,
        camp_year: CampConfiguration.active_camp_year
      )
      link_payment_request_to_receipt(payment)
      if params['transactionStatus'] != '1'
        redirect_to all_payments_path, alert: 'Your payment was not successful'
      else
        redirect_to all_payments_path, notice: 'Your payment was successfully recorded'
      end
    end
  end

  def make_payment
    result = generate_hash(params['amount'])
    PaymentRequest.create!(
      user_id: current_user.id,
      order_number: result[:order_number],
      amount_cents: result[:amount_cents],
      camp_year: CampConfiguration.active_camp_year,
      request_timestamp: result[:request_timestamp]
    )
    redirect_to result[:url]
  end

  def payment_show
    redirect_to root_url unless current_user.payments.current_camp_payments
     @registration_activities = registration_activities
     @has_any_session = session_registrations.pluck(:description).include?("Any Session")
     @current_application_status = current_application_status
     @finaids = finaids
     @finaids_ttl = finaids_ttl
     @users_current_payments = users_current_payments
     @ttl_paid = ttl_paid
     @total_cost = total_cost
     @balance_due = balance_due
     @session_registrations = session_registrations
  end

  private

    def set_current_enrollment
      @current_enrollment = current_user.enrollments.current_camp_year_applications.last
    end

    def generate_hash(amount = current_camp_fee / 100)
      user_account = current_user.email.partition('@').first + '-' + current_user.id.to_s
      amount_to_be_payed = amount.to_i
      if Rails.env.development? || Rails.application.credentials.NELNET_SERVICE[:SERVICE_SELECTOR] == "QA"
        key_to_use = 'test_key'
        url_to_use = 'test_URL'
      else
        key_to_use = 'prod_key'
        url_to_use = 'prod_URL'
      end

      connection_hash = {
        'test_key' => Rails.application.credentials.NELNET_SERVICE[:DEVELOPMENT_KEY],
        'test_URL' => Rails.application.credentials.NELNET_SERVICE[:DEVELOPMENT_URL],
        'prod_key' => Rails.application.credentials.NELNET_SERVICE[:PRODUCTION_KEY],
        'prod_URL' => Rails.application.credentials.NELNET_SERVICE[:PRODUCTION_URL]
      }

      redirect_url = connection_hash[url_to_use]
      current_epoch_time = DateTime.now.strftime("%Q").to_i
      initial_hash = {
        'orderNumber' => user_account,
        'orderType' => 'MMSS Univ of Michigan',
        'orderDescription' => 'MMSS Conference Fees',
        'amountDue' => amount_to_be_payed * 100,
        'redirectUrl' => redirect_url,
        'redirectUrlParameters' => 'transactionType,transactionStatus,transactionId,transactionTotalAmount,transactionDate,transactionAcountType,transactionResultCode,transactionResultMessage,orderNumber',
        'timestamp' => current_epoch_time,
        'key' => connection_hash[key_to_use]
      }

      # Sample Hash Creation
      hash_to_be_encoded = initial_hash.values.map { |v| "#{v}" }.join('')
      encoded_hash = Digest::SHA256.hexdigest hash_to_be_encoded

      # Final URL
      url_for_payment = initial_hash.map { |k, v| "#{k}=#{v}&" unless k == 'key' }.join('')
      final_url = connection_hash[url_to_use] + '?' + url_for_payment + 'hash=' + encoded_hash

      {
        url: final_url,
        order_number: user_account,
        amount_cents: amount_to_be_payed * 100,
        request_timestamp: current_epoch_time
      }
    end

    def log_nelnet_callback
      NelnetCallbackLog.create!(
        transaction_id: params['transactionId'],
        order_number: params['orderNumber'],
        transaction_status: params['transactionStatus'],
        transaction_total_amount: params['transactionTotalAmount'],
        raw_params: params.to_unsafe_h.slice(
          'transactionType', 'transactionStatus', 'transactionId', 'transactionTotalAmount',
          'transactionDate', 'transactionAcountType', 'transactionResultCode', 'transactionResultMessage',
          'orderNumber', 'timestamp', 'hash'
        ).to_json
      )
    rescue StandardError => e
      Rails.logger.error("[NelnetCallbackLog] Failed to log callback: #{e.message}")
    end

    def link_payment_request_to_receipt(payment)
      return unless payment && params['orderNumber'].present?

      PaymentRequest
        .unmatched
        .where(user_id: current_user.id, order_number: params['orderNumber'])
        .order(created_at: :asc)
        .limit(1)
        .update_all(payment_id: payment.id)
    end

    def url_params
      params.permit(:amount, :transactionType, :transactionStatus, :transactionId, :transactionTotalAmount, :transactionDate, :transactionAcountType, :transactionResultCode, :transactionResultMessage, :orderNumber, :timestamp, :hash, :camp_year)
    end
end
