# frozen_string_literal: true

# Logs every HTTP request that hits payment_receipt (GET or POST from Nelnet redirect).
# Written before authentication so we record callbacks even when the user session is missing.
# Use to verify "Nelnet says they sent it" by searching for transaction_id or order_number.

# == Schema Information
#
# Table name: nelnet_callback_logs
#
#  id                                                     :bigint           not null, primary key
#  transaction_id(Nelnet transactionId from callback)     :string(255)
#  order_number(orderNumber from callback (user_account)) :string(255)
#  transaction_status                                     :string(255)
#  transaction_total_amount                               :string(255)
#  raw_params(Full request params as JSON)                :text(65535)
#  created_at                                             :datetime         not null
#  updated_at                                             :datetime         not null
#
# Indexes
#
#  index_nelnet_callback_logs_on_created_at      (created_at)
#  index_nelnet_callback_logs_on_order_number    (order_number)
#  index_nelnet_callback_logs_on_transaction_id  (transaction_id)
#
class NelnetCallbackLog < ApplicationRecord
  # No associations; this is a raw request log
  # raw_params stores the full params hash as JSON

  # raw_params pretty-printed when it is valid JSON, otherwise verbatim.
  def pretty_raw_params
    return raw_params if raw_params.blank?

    JSON.pretty_generate(JSON.parse(raw_params))
  rescue JSON::ParserError
    raw_params
  end
end
