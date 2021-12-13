# == Schema Information
#
# Table name: travels
#
#  id               :bigint           not null, primary key
#  enrollment_id    :bigint           not null
#  direction        :string(255)
#  transport_needed :string(255)
#  date             :datetime
#  mode             :string(255)
#  carrier          :string(255)
#  route_num        :string(255)
#  note             :text(65535)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
require 'rails_helper'

RSpec.describe Travel, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
