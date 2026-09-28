# frozen_string_literal: true

# Index filters for Admin::UsersController (the ActiveAdmin resource only filtered on email).
class Admin::UsersFilter < Admin::Filter
  text :email, match: :contains
end
