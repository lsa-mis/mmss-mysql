# frozen_string_literal: true

# Index filters for Admin::FeedbacksController. Mirrors ActiveAdmin's auto-generated filter set
# (every ransackable attribute plus the user association). The controller's base relation
# left-joins users for the sort; the user filter binds on feedbacks.user_id directly.
class Admin::FeedbacksFilter < Admin::Filter
  select :user_id, label: 'User', collection: -> { User.where(id: Feedback.select(:user_id)).order(:email).pluck(:email, :id) }
  select :genre, collection: -> { Feedback::GENRES.map { |value, label| [label, value] } }
  text :message, match: :contains
  number :id, label: 'ID'
  date_range :created_at
  date_range :updated_at
end
