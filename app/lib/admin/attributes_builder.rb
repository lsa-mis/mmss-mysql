# frozen_string_literal: true

# Collects the rows for Admin::PanelHelper#admin_attributes (a show-page attribute list).
class Admin::AttributesBuilder
  Row = Struct.new(:label, :block, keyword_init: true)

  attr_reader :rows

  def initialize
    @rows = []
  end

  # row :offer_status                     -> record.offer_status, label "Offer status"
  # row 'Applicant' do |record| ... end
  # row :offer_status, :application_status, :campyear (several attribute rows at once)
  def row(*names, &block)
    if block
      name = names.first
      label = name.is_a?(Symbol) ? name.to_s.humanize : name.to_s
      rows << Row.new(label: label, block: block)
    else
      names.each do |name|
        rows << Row.new(label: name.to_s.humanize, block: ->(record) { record.public_send(name) })
      end
    end
    self
  end
end
