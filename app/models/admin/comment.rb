# frozen_string_literal: true

# == Schema Information
#
# Table name: admin_comments
#
#  id            :bigint           not null, primary key
#  author_id     :bigint
#  author_type   :string(255)
#  body          :text(65535)
#  created_at    :datetime         not null
#  namespace     :string(255)
#  resource_id   :bigint
#  resource_type :string(255)
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_admin_comments_on_author_type_and_author_id      (author_type,author_id)
#  index_admin_comments_on_namespace                      (namespace)
#  index_admin_comments_on_resource_type_and_resource_id  (resource_type,resource_id)
#
# Admin comments on any admin-managed record. The table is the legacy admin's
# `active_admin_comments` table, renamed so the existing comments survived the cutover.
#
# `namespace` is a leftover of the legacy admin, which scoped comments per admin namespace: rows
# written before the cutover carry 'admin' (or 'legacy_admin' from the side-by-side period). The
# new admin writes NAMESPACE and reads every namespace, so nothing is hidden. The column stays
# (and stays NOT blank) only so old rows keep their provenance; nothing filters on it.
class Admin::Comment < ApplicationRecord
  self.table_name = "admin_comments"

  NAMESPACE = "admin"

  # Models that accept admin comments (they must `include AdminCommentable`). Add an entry when
  # a resource's show page renders the comments partial. Lambdas keep
  # autoloading lazy, and looking classes up here means user input is never constantized.
  COMMENTABLE_MODELS = {
    "Enrollment" => -> { Enrollment },
    "CampOccurrence" => -> { CampOccurrence },
    "Activity" => -> { Activity },
    "Course" => -> { Course },
    "CourseAssignment" => -> { CourseAssignment },
    "SessionActivity" => -> { SessionActivity },
    "SessionAssignment" => -> { SessionAssignment },
    "Recommendation" => -> { Recommendation },
    "Recupload" => -> { Recupload },
    "ApplicantDetail" => -> { ApplicantDetail },
    "FinancialAid" => -> { FinancialAid }
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
end
