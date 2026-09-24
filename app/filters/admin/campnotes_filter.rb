# frozen_string_literal: true

# Index filters for Admin::CampnotesController (ActiveAdmin generated these from the model's
# ransackable attributes).
class Admin::CampnotesFilter < Admin::Filter
  text :note, match: :contains
  select :notetype, label: 'Note type', collection: -> { Campnote.where.not(notetype: [nil, '']).distinct.order(:notetype).pluck(:notetype) }
  date_range :opendate, label: 'Open date'
  date_range :closedate, label: 'Close date'
  date_range :created_at
  date_range :updated_at
end
