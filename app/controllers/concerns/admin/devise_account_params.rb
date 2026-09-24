# frozen_string_literal: true

# Strong-params handling for Devise account resources (Admins, Users) managed from the admin.
#
# Creating an account requires a password; editing one must not, so an admin can change an
# email address without resetting the password. When both password fields are blank on
# update they are dropped from the attributes so Devise's `validatable` does not run the
# password validations (ActiveAdmin's Users controller did the same in its `update` override).
module Admin::DeviseAccountParams
  extend ActiveSupport::Concern

  PASSWORD_PARAMS = %i[password password_confirmation].freeze

  private

  def account_params(model_key)
    params.require(model_key).permit(:email, *PASSWORD_PARAMS)
  end

  def account_params_for_update(model_key)
    attributes = account_params(model_key)
    return attributes if PASSWORD_PARAMS.any? { |key| attributes[key].present? }

    attributes.except(*PASSWORD_PARAMS)
  end
end
