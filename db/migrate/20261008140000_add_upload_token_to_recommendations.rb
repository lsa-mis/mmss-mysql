# frozen_string_literal: true

# The recommender upload link used to carry the recommendation id behind a constant prefix, so it
# was guessable. It now carries a random, expiring, single-use token (Recommendation#upload_token).
class AddUploadTokenToRecommendations < ActiveRecord::Migration[8.1]
  def change
    # Binary collation: the table default (utf8mb4_0900_ai_ci) compares case-insensitively,
    # which would let a differently cased string match a token and shrink the base58 alphabet.
    add_column :recommendations, :upload_token, :string, collation: 'utf8mb4_bin'
    add_column :recommendations, :upload_token_expires_at, :datetime
    add_index :recommendations, :upload_token, unique: true
  end
end
