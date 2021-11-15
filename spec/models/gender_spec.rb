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
  it { should validate_presence_of(:name) }
end
