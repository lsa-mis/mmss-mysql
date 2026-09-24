# frozen_string_literal: true

# == Schema Information
#
# Table name: active_admin_comments
#
#  id            :bigint           not null, primary key
#  namespace     :string(255)
#  body          :text(65535)
#  resource_type :string(255)
#  resource_id   :bigint
#  author_type   :string(255)
#  author_id     :bigint
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_active_admin_comments_on_author_type_and_author_id      (author_type,author_id)
#  index_active_admin_comments_on_namespace                      (namespace)
#  index_active_admin_comments_on_resource_type_and_resource_id  (resource_type,resource_id)
#
# Admin comments on any admin-managed record. Reuses the ActiveAdmin comments table so the
# existing comments survive the cutover; the table is renamed once ActiveAdmin is removed.
class Admin::Comment < ApplicationRecord
  self.table_name = 'active_admin_comments'

  NAMESPACE = 'admin'

  # Models that accept admin comments (they must `include AdminCommentable`). Add an entry when
  # porting a resource whose ActiveAdmin show page rendered `active_admin_comments`. Lambdas keep
  # autoloading lazy, and looking classes up here means user input is never constantized.
  COMMENTABLE_MODELS = {
    'Enrollment' => -> { Enrollment },
    'CampOccurrence' => -> { CampOccurrence },
    'Activity' => -> { Activity },
    'Course' => -> { Course }
  }.freeze

  def self.commentable_class(type)
    COMMENTABLE_MODELS[type.to_s]&.call
  end

  belongs_to :resource, polymorphic: true
  belongs_to :author, polymorphic: true

  validates :body, presence: true
  validates :namespace, presence: true

  attribute :namespace, :string, default: NAMESPACE

  scope :recent_first, -> { order(created_at: :desc) }
  scope :for_resource, ->(resource) { where(resource: resource) }

  def self.ransackable_attributes(_auth_object = nil) = %w[body created_at namespace resource_type author_type]

  def self.ransackable_associations(_auth_object = nil) = %w[]
end
