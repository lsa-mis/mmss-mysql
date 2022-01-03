# == Schema Information
#
# Table name: genders
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  description :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Gender < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :gender_filter, -> do
    Gender.table_exists? ? Gender.all.map{|a| [a.name, a.id]} : {}
  end
end
