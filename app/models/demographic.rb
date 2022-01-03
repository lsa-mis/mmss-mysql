# == Schema Information
#
# Table name: demographics
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  description :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Demographic < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :description, presence: true, uniqueness: { case_sensitive: false }, length: {maximum: 2250}
  
  scope :demographic_filter, -> do
    Demographic.table_exists? ? Demographic.all.map{|a| [a.name, a.id]} : {}
  end
end
