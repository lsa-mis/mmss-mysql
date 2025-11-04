# frozen_string_literal: true

# == Schema Information
#
# Table name: campnotes
#
#  id         :bigint           not null, primary key
#  note       :string(255)
#  opendate   :datetime
#  closedate  :datetime
#  notetype   :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe Campnote, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
