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
class Gender < ApplicationRecord
  validates :name, presence: true, uniqueness: {case_sensitive: false} # standard:disable Rails/UniqueValidationWithoutIndex -- no DB index yet; adding one is a schema change (see #275 for the payments precedent)
end
