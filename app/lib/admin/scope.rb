# frozen_string_literal: true

# A named scope tab on an admin index page (the equivalent of ActiveAdmin's `scope`).
#
#   Admin::Scope.new(:current_camp_year_applications, label: 'Current years Applications', default: true)
#   Admin::Scope.new(:offered, group: :offer_status)
#   Admin::Scope.new(:unmatched, label: 'Unmatched') { |relation| relation.where(payment_id: nil) }
#
# Without a block the scope calls the model scope/class method of the same name.
class Admin::Scope
  attr_reader :name, :label, :group, :block

  def initialize(name, label: nil, group: nil, default: false, &block)
    @name = name.to_sym
    @label = label || name.to_s.humanize
    @group = group&.to_sym
    @default = default
    @block = block
  end

  def default? = @default

  def param = name.to_s

  def apply(relation)
    block ? block.call(relation) : relation.public_send(name)
  end
end
