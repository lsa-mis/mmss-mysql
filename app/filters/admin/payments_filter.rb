# frozen_string_literal: true

# Index filters for Admin::PaymentsController (the ActiveAdmin set: user, account type, camp
# year, created_at).
class Admin::PaymentsFilter < Admin::Filter
  select :user_id, label: 'User', collection: -> { User.order(:email).pluck(:email, :id) }
  select :account_type, collection: -> { distinct_values(:account_type) }
  select :camp_year, collection: -> { distinct_values(:camp_year, order: :desc) }
  date_range :created_at

  def self.distinct_values(column, order: :asc)
    Payment.where.not(column => [nil, '']).distinct.order(column => order).pluck(column)
  end
end
