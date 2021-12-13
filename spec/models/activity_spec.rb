# == Schema Information
#
# Table name: activities
#
#  id                 :bigint           not null, primary key
#  camp_occurrence_id :bigint
#  description        :string(255)
#  cost_cents         :integer
#  date_occurs        :date
#  active             :boolean          default(FALSE)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
require 'rails_helper'

RSpec.describe Activity, type: :model do
  it { should validate_presence_of(:description) }
  it { should validate_numericality_of(:cost_cents) }
  it { should validate_presence_of(:date_occurs) }
end
