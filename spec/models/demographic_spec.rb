# frozen_string_literal: true

# == Schema Information
#
# Table name: demographics
#
#  id          :bigint           not null, primary key
#  name        :string(255)      not null
#  description :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  protected   :boolean          default(FALSE)
#
require 'rails_helper'

RSpec.describe Demographic, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
