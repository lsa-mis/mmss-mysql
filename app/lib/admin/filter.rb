# frozen_string_literal: true

# Declarative, hand-rolled filter objects for admin index pages (replaces Ransack).
#
#   class Admin::ApplicationsFilter < Admin::Filter
#     text :lastname, label: 'Last Name (Starts with)', match: :starts_with,
#                     column: 'applicant_details.lastname', joins: :applicant_detail
#     boolean :international
#     select :application_status, collection: -> { Enrollment.distinct.pluck(:application_status) }
#     date_range :application_deadline
#     number :campyear
#   end
#
#   filter = Admin::ApplicationsFilter.new(params[:q])
#   relation = filter.apply(Enrollment.all)
#
# Values arrive as `q[<name>]` (date ranges as `q[<name>_from]` / `q[<name>_to]`). Only declared
# fields are read, column names are developer-supplied constants, and values are always bound, so
# user input never reaches SQL unescaped. Rendering is handled by Admin::FilterHelper.
class Admin::Filter
  PARAM_KEY = :q
  TYPES = %i[text select boolean date_range number].freeze

  Field = Struct.new(:name, :type, :label, :column, :joins, :match, :collection, :datetime, :html,
                     keyword_init: true) do
    def param = name.to_s

    def from_param = "#{name}_from"

    def to_param = "#{name}_to"

    def params = type == :date_range ? [from_param, to_param] : [param]

    # Collections may be lazy (a lambda) so the query runs when the form renders, not at boot.
    def options
      list = collection.respond_to?(:call) ? collection.call : collection
      Array(list).map { |item| item.is_a?(Array) ? item : [item.to_s, item] }
    end
  end

  class << self
    def fields
      @fields ||= []
    end

    def inherited(subclass)
      super
      subclass.instance_variable_set(:@fields, fields.dup)
    end

    # `match:` is :contains (default), :starts_with or :equals.
    def text(name, match: :contains, **) = add_field(:text, name, match: match, **)

    # `collection:` is an array of values, `[label, value]` pairs, or a lambda returning either.
    def select(name, collection:, **) = add_field(:select, name, collection: collection, **)

    def boolean(name, **) = add_field(:boolean, name, **)

    # Renders a from/to pair of date inputs. `datetime: true` widens the upper bound to end of day;
    # it is inferred from the model column when the column belongs to the filtered model.
    def date_range(name, datetime: nil, **) = add_field(:date_range, name, datetime: datetime, **)

    def number(name, **) = add_field(:number, name, **)

    private

    def add_field(type, name, label: nil, column: nil, joins: nil, html: {}, **options)
      fields << Field.new(name: name.to_sym, type: type, label: label || name.to_s.humanize,
                          column: (column || name).to_s, joins: joins, html: html, **options)
    end
  end

  attr_reader :values

  def initialize(params)
    raw = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : (params || {})
    # Only scalar values are meaningful (`q[lastname][]=x` or `q[lastname][a]=x` are discarded).
    @values = raw.to_h.stringify_keys
                 .slice(*permitted_params)
                 .select { |_key, value| value.is_a?(String) || value.is_a?(Numeric) }
                 .transform_values { |value| value.to_s.strip }
                 .compact_blank
  end

  def fields = self.class.fields

  def value(param) = values[param.to_s]

  def active? = values.any?

  def permitted_params = fields.flat_map(&:params)

  # Query params to carry the active filter across sort/pagination/CSV links.
  def to_params
    active? ? { PARAM_KEY => values } : {}
  end

  def apply(relation)
    fields.reduce(relation) do |scope, field|
      next scope unless field.params.any? { |param| values.key?(param) }

      scope = scope.joins(field.joins) if field.joins
      send(:"apply_#{field.type}", scope, field)
    end
  end

  private

  def apply_text(scope, field)
    column = qualified_column(scope, field)
    term = value(field.param)

    case field.match
    when :equals then scope.where("#{column} = ?", term)
    when :starts_with then scope.where("#{column} LIKE ?", "#{scope.model.sanitize_sql_like(term)}%")
    else scope.where("#{column} LIKE ?", "%#{scope.model.sanitize_sql_like(term)}%")
    end
  end

  def apply_select(scope, field)
    scope.where("#{qualified_column(scope, field)} = ?", value(field.param))
  end
  alias apply_number apply_select

  def apply_boolean(scope, field)
    truthy = ActiveModel::Type::Boolean.new.cast(value(field.param))
    return scope if truthy.nil?

    scope.where("#{qualified_column(scope, field)} = ?", truthy)
  end

  def apply_date_range(scope, field)
    column = qualified_column(scope, field)
    from = parse_date(value(field.from_param))
    to = parse_date(value(field.to_param))
    datetime = field.datetime.nil? ? datetime_column?(scope, field) : field.datetime

    scope = scope.where("#{column} >= ?", datetime ? from.beginning_of_day : from) if from
    scope = scope.where("#{column} <= ?", datetime ? to.end_of_day : to) if to
    scope
  end

  def parse_date(string)
    return nil if string.blank?

    Date.parse(string)
  rescue ArgumentError, TypeError
    nil
  end

  def qualified_column(scope, field)
    field.column.include?('.') ? field.column : "#{scope.model.table_name}.#{field.column}"
  end

  def datetime_column?(scope, field)
    return false if field.column.include?('.')

    scope.model.columns_hash[field.column]&.type == :datetime
  end
end
