# frozen_string_literal: true

# Scope tabs (`?scope=<name>`) for admin index pages.
#
#   SCOPES = [Admin::Scope.new(:current_camp, default: true), Admin::Scope.new(:all)].freeze
#
#   @applications = apply_scope(Enrollment.all, SCOPES)
#
# The chosen scope is exposed to the view as `current_scope`; the scope tabs partial uses
# `scope_counts(base, SCOPES)` to show the record count next to each tab.
module Admin::Scopable
  extend ActiveSupport::Concern

  included do
    helper_method :current_scope
  end

  def apply_scope(relation, scopes)
    @current_scope = scopes.find { |scope| scope.param == params[:scope].to_s } ||
                     scopes.find(&:default?) ||
                     scopes.first
    @current_scope ? @current_scope.apply(relation) : relation
  end

  def current_scope = @current_scope

  # Counts are computed against the unscoped-but-filtered relation so the numbers reflect the
  # active filters, the same way ActiveAdmin did.
  def scope_counts(relation, scopes)
    scopes.index_with { |scope| scope.apply(relation).count }
  end
end
