# frozen_string_literal: true

# Parent of every controller in the new admin (/admin). Requires a signed-in Devise `Admin`,
# renders in the admin layout and mixes in the shared index building blocks (sorting,
# pagination, scopes, batch actions, CSV export).
#
# `Admin` is the Devise model class, so controllers are declared in compact form
# (`class Admin::FooController`) rather than `module Admin`.
class Admin::BaseController < ApplicationController
  include Admin::Sortable
  include Admin::Paginatable
  include Admin::Scopable
  include Admin::BatchActionable
  include Admin::CsvExportable

  before_action :authenticate_admin!

  layout 'admin'

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def record_not_found
    redirect_to admin_root_path, alert: 'The record you were looking for could not be found.', status: :see_other
  end
end
