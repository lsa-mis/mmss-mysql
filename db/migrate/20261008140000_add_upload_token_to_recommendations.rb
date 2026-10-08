# frozen_string_literal: true

# The recommender upload link used to carry the recommendation id behind a constant prefix, so it
# was guessable. It now carries a random, expiring, single-use token (Recommendation#upload_token).
class AddUploadTokenToRecommendations < ActiveRecord::Migration[8.1]
  def change
    add_column :recommendations, :upload_token, :string
    add_column :recommendations, :upload_token_expires_at, :datetime
    add_index :recommendations, :upload_token, unique: true
  end
end
