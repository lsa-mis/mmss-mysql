# frozen_string_literal: true

# == Schema Information
#
# Table name: session_assignments
#
#  id                 :bigint           not null, primary key
#  enrollment_id      :bigint           not null
#  camp_occurrence_id :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  offer_status       :string(255)
#
require 'rails_helper'

RSpec.describe SessionAssignment, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
