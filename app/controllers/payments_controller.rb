# frozen_string_literal: true

require 'digest'
require 'time'

class PaymentsController < ApplicationController
  include ApplicantState

  # Order matches redirectUrlParameters sent to Nelnet in #generate_hash (values concatenated + timestamp + key).
  NELNET_RECEIPT_SIGNATURE_PARAM_ORDER = %w[
    transactionType transactionStatus transactionId transactionTotalAmount transactionDate
    transactionAcountType transactionResultCode transactionResultMessage orderNumber
  ].freeze

  skip_before_action :verify_authenticity_token, only: [:payment_receipt]
  devise_group :logged_in, contains: [:user, :admin]
  prepend_before_action :log_nelnet_callback, only: [:payment_receipt]
  before_action :authenticate_logged_in!
  skip_before_action :authenticate_logged_in!, only: [:payment_receipt]
  before_action :authenticate_admin!, only: [:index, :destroy]

  before_action :set_current_enrollment
  skip_before_action :set_current_enrollment, only: [:payment_receipt]
  before_action :identify_user_for_payment_receipt!, only: [:payment_receipt]
  before_action :validate_nelnet_receipt_signature!, only: [:payment_receipt]
  before_action :verify_payment_request_for_new_transaction!, only: [:payment_receipt]

  def index
    redirect_to root_url
  end

  def payment_receipt
    tid = params['transactionId'].to_s
    existing = Payment.find_by(transaction_id: tid)

    if existing
      reject_payment_receipt_if_payment_user_mismatch!(existing)
      return if performed?

      link_payment_request_to_receipt(existing)
      redirect_to payment_receipt_completion_path
      return
    end

    payment = Payment.create(
      transaction_type: params['transactionType'],
      transaction_status: params['transactionStatus'],
      transaction_id: tid,
      total_amount: params['transactionTotalAmount'],
      transaction_date: params['transactionDate'],
      account_type: params['transactionAcountType'],
      result_code: params['transactionResultCode'],
      result_message: params['transactionResultMessage'],
      user_account: params['orderNumber'],
      payer_identity: payment_receipt_user.email,
      timestamp: params['timestamp'],
      transaction_hash: params['hash'],
      user_id: payment_receipt_user.id,
      camp_year: CampConfiguration.active_camp_year
    )

    unless payment.persisted?
      if payment.errors.of_kind?(:transaction_id, :taken)
        payment = Payment.find_by(transaction_id: tid)
      end
    end

    unless payment&.persisted?
      redirect_to payment_receipt_completion_path, alert: 'Unable to record payment.'
      return
    end

    reject_payment_receipt_if_payment_user_mismatch!(payment)
    return if performed?

    link_payment_request_to_receipt(payment)
    if params['transactionStatus'] != '1'
      redirect_to payment_receipt_completion_path, alert: 'Your payment was not successful'
    else
      redirect_to payment_receipt_completion_path, notice: 'Your payment was successfully recorded'
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
    return if @current_enrollment.present?

    redirect_to root_url, alert: 'No current enrollment found for this camp year.' and return
  end

  def generate_hash(amount = current_camp_fee / 100)
    user_account = current_user.email.partition('@').first + '-' + current_user.id.to_s
    amount_to_be_payed = amount.to_i
    if Rails.env.development? || Rails.application.credentials.NELNET_SERVICE[:SERVICE_SELECTOR] == "QA"
      url_to_use = 'test_URL'
    else
      url_to_use = 'prod_URL'
    end

    connection_hash = {
      'test_URL' => Rails.application.credentials.NELNET_SERVICE[:DEVELOPMENT_URL],
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
      'redirectUrlParameters' => NELNET_RECEIPT_SIGNATURE_PARAM_ORDER.join(','),
      'timestamp' => current_epoch_time,
      'key' => nelnet_signing_key
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
      .where(user_id: payment_receipt_user.id, order_number: params['orderNumber'])
      .order(created_at: :asc)
      .limit(1)
      .update_all(payment_id: payment.id)
  end

  def payment_receipt_user
    @payment_receipt_user || current_user
  end

  def payment_receipt_completion_path
    logged_in_signed_in? ? all_payments_path : new_user_session_path
  end

  def reject_payment_receipt_if_payment_user_mismatch!(payment)
    return if payment.blank?
    return if payment.user_id == payment_receipt_user.id

    Rails.logger.warn(
      "Payment receipt user mismatch for transaction_id=#{params['transactionId']}, " \
      "payment_user_id=#{payment.user_id}, receipt_user_id=#{payment_receipt_user.id}, " \
      "order_number=#{params['orderNumber']}"
    )
    redirect_to payment_receipt_completion_path, alert: 'Payment receipt could not be verified'
  end

  def identify_user_for_payment_receipt!
    return if performed?

    order_number = params['orderNumber'].to_s
    if order_number.blank?
      redirect_to new_user_session_path, alert: 'Invalid payment callback.'
      return
    end

    user_id = order_number.match(/\A.*-(\d+)\z/)&.[](1)&.to_i
    candidate = user_id&.positive? ? User.find_by(id: user_id) : nil
    matching_payment_request = candidate && PaymentRequest.where(user_id: candidate.id, order_number: order_number).exists?

    if candidate.blank? || !matching_payment_request
      Rails.logger.warn('[PaymentsController] Rejected payment_receipt: orderNumber did not match a stored payment request')
      redirect_to new_user_session_path,
                  alert: 'Unable to verify payment. Please sign in; contact support if your account was charged.'
      return
    end

    @payment_receipt_user = candidate
  end

  def validate_nelnet_receipt_signature!
    return if performed?

    actual = params['hash'].to_s.strip
    if actual.blank?
      Rails.logger.warn('[PaymentsController] Rejected payment_receipt: missing hash')
      redirect_to new_user_session_path,
                  alert: 'Unable to verify payment. Please sign in; contact support if your account was charged.'
      return
    end

    payload = nelnet_receipt_signature_payload
    expected = Digest::SHA256.hexdigest(payload)
    actual_down = actual.downcase
    unless actual_down.match?(/\A[a-f0-9]{64}\z/) &&
           ActiveSupport::SecurityUtils.secure_compare(expected, actual_down)
      Rails.logger.warn('[PaymentsController] Rejected payment_receipt: invalid Nelnet hash')
      redirect_to new_user_session_path,
                  alert: 'Unable to verify payment. Please sign in; contact support if your account was charged.'
      return
    end
  end

  def verify_payment_request_for_new_transaction!
    return if performed?

    tid = params['transactionId'].to_s
    return if tid.present? && Payment.exists?(transaction_id: tid)

    if params['timestamp'].blank?
      Rails.logger.warn('[PaymentsController] Rejected payment_receipt: missing timestamp')
      redirect_to new_user_session_path,
                  alert: 'Unable to verify payment. Please sign in; contact support if your account was charged.'
      return
    end

    amount_cents = params['transactionTotalAmount'].to_i
    ts = params['timestamp'].to_i

    matched = PaymentRequest.unmatched.exists?(
      user_id: payment_receipt_user.id,
      order_number: params['orderNumber'].to_s,
      amount_cents: amount_cents,
      request_timestamp: ts,
      camp_year: CampConfiguration.active_camp_year
    )

    unless matched
      Rails.logger.warn('[PaymentsController] Rejected payment_receipt: no matching PaymentRequest')
      redirect_to new_user_session_path,
                  alert: 'Unable to verify payment. Please sign in; contact support if your account was charged.'
      return
    end
  end

  # Return-url digest mirrors the outbound redirectUrlParameters order, then timestamp, then the Nelnet key (see #generate_hash).
  def nelnet_receipt_signature_payload
    NELNET_RECEIPT_SIGNATURE_PARAM_ORDER.map { |k| params[k].to_s }.join + params['timestamp'].to_s + nelnet_signing_key
  end

  def nelnet_signing_key
    if Rails.env.development? || Rails.application.credentials.NELNET_SERVICE[:SERVICE_SELECTOR] == "QA"
      Rails.application.credentials.NELNET_SERVICE[:DEVELOPMENT_KEY]
    else
      Rails.application.credentials.NELNET_SERVICE[:PRODUCTION_KEY]
    end
  end

  def url_params
    params.permit(
      :amount,
      :transactionType,
      :transactionStatus,
      :transactionId,
      :transactionTotalAmount,
      :transactionDate,
      :transactionAcountType,
      :transactionResultCode,
      :transactionResultMessage,
      :orderNumber,
      :timestamp,
      :hash,
      :camp_year
    )
  end
end
