# frozen_string_literal: true

# == Schema Information
#
# Table name: genders
#
#  id          :bigint           not null, primary key
#  name        :string(255)      not null
#  description :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe Gender, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
