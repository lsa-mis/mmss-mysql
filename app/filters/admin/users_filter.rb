# frozen_string_literal: true

# Index filters for Admin::UsersController (email only, as in the legacy admin).
class Admin::UsersFilter < Admin::Filter
  text :email, match: :contains
end
