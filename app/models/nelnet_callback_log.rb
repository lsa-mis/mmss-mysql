# frozen_string_literal: true

# Logs every HTTP request that hits payment_receipt (GET or POST from Nelnet redirect).
# Written before authentication so we record callbacks even when the user session is missing.
# Use to verify "Nelnet says they sent it" by searching for transaction_id or order_number.
class NelnetCallbackLog < ApplicationRecord
  # No associations; this is a raw request log
  # raw_params stores the full params hash as JSON
end
