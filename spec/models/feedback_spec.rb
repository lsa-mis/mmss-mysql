# frozen_string_literal: true

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
# Indexes
#
#  index_feedbacks_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Feedback, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
