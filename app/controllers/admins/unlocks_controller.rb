# frozen_string_literal: true

module Admins
  class UnlocksController < Devise::UnlocksController
    layout 'admin_auth'
  end
end
