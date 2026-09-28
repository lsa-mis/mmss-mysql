# frozen_string_literal: true

# == Schema Information
#
# Table name: activities
#
#  id                 :bigint           not null, primary key
#  camp_occurrence_id :bigint
#  description        :string(255)
#  cost_cents         :integer
#  date_occurs        :date
#  active             :boolean          default(FALSE)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_activities_on_camp_occurrence_id  (camp_occurrence_id)
#
# Foreign Keys
#
#  fk_rails_...  (camp_occurrence_id => camp_occurrences.id)
#
class Activity < ApplicationRecord
  include MoneyRails::ActionViewExtension
  include AdminCommentable

  belongs_to :camp_occurrence
  has_many :enrollment_activities, dependent: :destroy
  has_many :enrolled_users, through: :enrollment_activities, source: :enrollment

  monetize :cost_cents

  validates :description, presence: true
  validates :date_occurs, presence: true, format: { with: ConstantData::VALID_DATE_REGEX }
  validates :cost_cents, presence: true, numericality: { only_integer: true }

  def description_with_cost
    "#{description} -- #{humanized_money_with_symbol(cost)}"
  end

  scope :active, -> { where(active: true).order(description: :asc) }

  def display_name
    "#{description} - #{camp_occurrence.description}" # or whatever column you want
  end
end
