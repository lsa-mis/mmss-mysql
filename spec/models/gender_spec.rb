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
  describe 'validations' do
    subject { build(:gender) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  it_behaves_like 'a model with timestamps'
end
