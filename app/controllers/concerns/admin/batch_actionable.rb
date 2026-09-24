# frozen_string_literal: true

# Batch actions for admin index pages. The index table renders a checkbox per row inside a form
# that posts to the resource's `batch` collection route with `batch_action=<name>` and `ids[]`.
#
#   class Admin::CoursesController < Admin::BaseController
#     BATCH_ACTIONS = {
#       destroy: 'Delete selected',
#       toggle_status: 'Toggle open/closed'
#     }.freeze
#
#     def batch
#       perform_batch_action(Course.all, BATCH_ACTIONS)
#     end
#
#     private
#
#     # Custom actions are `batch_<name>(records)`; `batch_destroy` is provided here.
#     def batch_toggle_status(records) ... end
#   end
module Admin::BatchActionable
  extend ActiveSupport::Concern

  def perform_batch_action(relation, batch_actions, redirect_to_path: url_for(action: :index))
    action = params[:batch_action].to_s.presence_in(batch_actions.keys.map(&:to_s))
    ids = Array(params[:ids]).map(&:presence).compact

    if action.nil?
      return redirect_to redirect_to_path, alert: 'Unknown batch action.', status: :see_other
    elsif ids.empty?
      return redirect_to redirect_to_path, alert: 'Select at least one record first.', status: :see_other
    end

    records = relation.where(id: ids)
    notice = public_send(:"batch_#{action}", records)
    redirect_to redirect_to_path, notice: notice, status: :see_other
  end

  private

  def batch_destroy(records)
    destroyed = records.to_a.count(&:destroy)
    "Deleted #{destroyed} #{records.model.model_name.human(count: destroyed).downcase}."
  end
end
