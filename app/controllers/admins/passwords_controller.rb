# frozen_string_literal: true

module Admins
  class PasswordsController < Devise::PasswordsController
    layout 'admin_auth'
  end
end
