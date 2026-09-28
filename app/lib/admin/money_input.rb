# frozen_string_literal: true

# Strict parsing of dollar amounts typed into admin forms (Payment#total_amount_dollars=,
# FinancialAid#amount=). Accepts digits or properly grouped thousands, an optional "$" and up to
# two decimals — "150", "150.25", "$1,500.50" — and nothing else: no signs, exponents, third
# decimals or arbitrary comma placement ("1,2,3" must not become $123). Returns whole cents or
# nil; callers turn nil into a validation error instead of coercing.
module Admin::MoneyInput
  FORMAT = /\A\$?(\d{1,3}(,\d{3})+|\d+)(\.\d{1,2})?\z/

  def self.valid?(input)
    input.to_s.strip.match?(FORMAT)
  end

  def self.parse_cents(input)
    text = input.to_s.strip
    return nil unless text.match?(FORMAT)

    (BigDecimal(text.delete(',').delete_prefix('$')) * 100).to_i
  end
end
