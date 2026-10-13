# frozen_string_literal: true

# One letter per recommendation, enforced by the database (the recommender upload link is
# single-use; two simultaneous submissions must not both succeed). The unique index is added
# before the old non-unique one is dropped so the foreign key always has an index to use.
#
# Legacy data may already hold several letters for one recommendation (the old upload form never
# checked on POST). The migration then FAILS and names the recommendations, so the deploy cannot
# complete in a weaker state than schema.rb describes: resolve the duplicates in /admin/recuploads
# and run db:migrate again. Check beforehand with:
#   SELECT recommendation_id, COUNT(*) FROM recuploads GROUP BY recommendation_id HAVING COUNT(*) > 1;
class AddUniqueIndexToRecuploadsRecommendationId < ActiveRecord::Migration[8.1]
  UNIQUE_INDEX = 'index_recuploads_on_recommendation_id_unique'
  LEGACY_INDEX = 'index_recuploads_on_recommendation_id'

  class DuplicateLettersError < StandardError; end

  def up
    duplicates = select_values('SELECT recommendation_id FROM recuploads GROUP BY recommendation_id HAVING COUNT(*) > 1')
    if duplicates.any?
      raise DuplicateLettersError,
            "recuploads holds more than one letter for recommendation(s) #{duplicates.join(', ')}. " \
            'Resolve the duplicates in /admin/recuploads (keep one letter per recommendation), then run db:migrate again.'
    end

    add_index :recuploads, :recommendation_id, unique: true, name: UNIQUE_INDEX unless index_exists?(:recuploads, :recommendation_id, name: UNIQUE_INDEX)
    remove_index :recuploads, name: LEGACY_INDEX if index_exists?(:recuploads, :recommendation_id, name: LEGACY_INDEX)
  end

  def down
    add_index :recuploads, :recommendation_id, name: LEGACY_INDEX unless index_exists?(:recuploads, :recommendation_id, name: LEGACY_INDEX)
    remove_index :recuploads, name: UNIQUE_INDEX if index_exists?(:recuploads, :recommendation_id, name: UNIQUE_INDEX)
  end
end
