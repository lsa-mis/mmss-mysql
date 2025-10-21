# frozen_string_literal: true

# == Schema Information
#
# Table name: session_activities
#
#  id                 :bigint           not null, primary key
#  enrollment_id      :bigint           not null
#  camp_occurrence_id :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
require 'rails_helper'

RSpec.describe SessionActivity, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
