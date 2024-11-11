# == Schema Information
#
# Table name: demographics
#
#  id          :bigint           not null, primary key
#  name        :string(255)      not null
#  description :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Demographic < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :description, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 2250 }
end
