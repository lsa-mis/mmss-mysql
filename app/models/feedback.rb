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
class Feedback < ApplicationRecord
  belongs_to :user

  MESSAGE_MAX_LENGTH = 255

  # Stored value => label shown to users (the public feedback form offers the same three).
  GENRES = {
    'page_error' => 'Error on Page',
    'layout_issue' => 'Layout Issue',
    'suggestion' => 'Suggestion'
  }.freeze

  validates :genre, presence: true
  validates :message, presence: true
  validates :message, length: { maximum: MESSAGE_MAX_LENGTH, message: "is too long (maximum is %{count} characters)" }

  def genre_label
    GENRES.fetch(genre, genre)
  end
end
