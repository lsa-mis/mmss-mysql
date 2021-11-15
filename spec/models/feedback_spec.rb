# == Schema Information
#
# Table name: feedbacks
#
#  id         :bigint           not null, primary key
#  genre      :string(255)
#  message    :string(255)
#  user_id    :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe Feedback, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
