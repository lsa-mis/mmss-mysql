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
class Feedback < ApplicationRecord
  belongs_to :user

  validates :genre, presence: true
  validates :message, presence: true
end
