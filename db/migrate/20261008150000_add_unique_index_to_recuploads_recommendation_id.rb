# frozen_string_literal: true

# One letter per recommendation, enforced by the database (the recommender upload link is
# single-use; two simultaneous submissions must not both succeed). The unique index is added
# before the old non-unique one is dropped so the foreign key always has an index to use.
#
# Legacy data may already hold several letters for one recommendation (the old upload form never
# checked on POST). In that case the index is NOT added and the migration says which
# recommendations to clean up (/admin/recuploads); re-run it afterwards with
#   bin/rails db:migrate:redo VERSION=20261008150000
# Recupload#recommendation_id is also validated for uniqueness in the model, so the app behaves
# the same either way; the index is the race-proof backstop.
class AddUniqueIndexToRecuploadsRecommendationId < ActiveRecord::Migration[8.1]
  UNIQUE_INDEX = 'index_recuploads_on_recommendation_id_unique'
  LEGACY_INDEX = 'index_recuploads_on_recommendation_id'

  def up
    duplicates = select_values('SELECT recommendation_id FROM recuploads GROUP BY recommendation_id HAVING COUNT(*) > 1')
    if duplicates.any?
      say "recuploads holds more than one letter for recommendation(s) #{duplicates.join(', ')}; " \
          "unique index not added. Resolve the duplicates in /admin/recuploads, then re-run: " \
          "bin/rails db:migrate:redo VERSION=#{version}", true
      return
    end

    add_index :recuploads, :recommendation_id, unique: true, name: UNIQUE_INDEX unless index_exists?(:recuploads, :recommendation_id, name: UNIQUE_INDEX)
    remove_index :recuploads, name: LEGACY_INDEX if index_exists?(:recuploads, :recommendation_id, name: LEGACY_INDEX)
  end

  def down
    return unless index_exists?(:recuploads, :recommendation_id, name: UNIQUE_INDEX)

    add_index :recuploads, :recommendation_id, name: LEGACY_INDEX unless index_exists?(:recuploads, :recommendation_id, name: LEGACY_INDEX)
    remove_index :recuploads, name: UNIQUE_INDEX
  end
end
