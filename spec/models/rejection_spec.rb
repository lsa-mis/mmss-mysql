# frozen_string_literal: true

# == Schema Information
#
# Table name: rejections
#
#  id            :bigint           not null, primary key
#  enrollment_id :bigint           not null
#  reason        :text(65535)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require 'rails_helper'

RSpec.describe Rejection, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
