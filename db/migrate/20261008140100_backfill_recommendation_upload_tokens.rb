# frozen_string_literal: true

# Issues a token to every recommendation that is still waiting for its letter, so the admin
# "Resend request" action (and the request email) work for pre-existing recommendations. The
# previously emailed id-based links stop working on deploy; recommendations whose letter has
# already been received get no token (the link is dead for them anyway).
#
# Uses a bare model so the migration does not depend on application code.
class BackfillRecommendationUploadTokens < ActiveRecord::Migration[8.1]
  TOKEN_TTL = 60.days

  class MigrationRecommendation < ActiveRecord::Base
    self.table_name = 'recommendations'
  end

  def up
    expires_at = TOKEN_TTL.from_now
    pending = MigrationRecommendation.where(upload_token: nil)
                                     .where('NOT EXISTS (SELECT 1 FROM recuploads WHERE recuploads.recommendation_id = recommendations.id)')

    pending.in_batches(of: 500) do |batch|
      batch.each do |recommendation|
        recommendation.update_columns(upload_token: SecureRandom.base58(24), upload_token_expires_at: expires_at)
      end
    end
  end

  def down
    MigrationRecommendation.update_all(upload_token: nil, upload_token_expires_at: nil)
  end
end
