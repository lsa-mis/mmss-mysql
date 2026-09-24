# frozen_string_literal: true

# Collects the column definitions for Admin::TableHelper#admin_table. See that helper for usage.
class Admin::TableBuilder
  Column = Struct.new(:label, :sort_key, :block, :html_class, keyword_init: true) do
    def sortable? = sort_key.present?
  end

  attr_reader :columns

  def initialize
    @columns = []
  end

  # column :offer_status                       -> record.offer_status, header "Offer status"
  # column :updated_at, sort: true             -> sortable by the "updated_at" sort key
  # column 'Applicant', sort: 'applicant' do |record| ... end
  def column(name_or_label, sort: nil, html_class: nil, &block)
    label = name_or_label.is_a?(Symbol) ? name_or_label.to_s.humanize : name_or_label.to_s
    sort_key = sort == true ? name_or_label.to_s : sort&.to_s
    block ||= ->(record) { record.public_send(name_or_label) }

    columns << Column.new(label: label, sort_key: sort_key, block: block, html_class: html_class)
    self
  end
end
