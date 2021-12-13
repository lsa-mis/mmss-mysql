# == Schema Information
#
# Table name: financial_aids
#
#  id                :bigint           not null, primary key
#  enrollment_id     :bigint           not null
#  amount_cents      :integer          default(0)
#  source            :string(255)
#  note              :text(65535)
#  status            :string(255)      default("pending")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  payments_deadline :date
#
require 'rails_helper'

RSpec.describe FinancialAid, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
