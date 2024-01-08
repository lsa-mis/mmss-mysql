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
class Activity < ApplicationRecord
  include MoneyRails::ActionViewExtension
  belongs_to :camp_occurrence
  has_many :enrollment_activities
  has_many :enrolled_users, through: :enrollment_activities, source: :enrollment

  monetize :cost_cents

  validates :description, presence: true
  validates :date_occurs, presence: true, format: { with: ConstantData::VALID_DATE_REGEX }
  validates :cost_cents, presence: true, numericality: { only_integer: true }

  def description_with_cost
    "#{description} -- #{humanized_money_with_symbol(self.cost)}"
  end

  scope :active, -> { where(active: true).order(description: :asc) }
  
  def display_name
    "#{self.description} - #{self.camp_occurrence.description}" # or whatever column you want
  end

  def self.ransackable_associations(auth_object = nil)
    ["camp_occurrence", "enrolled_users", "enrollment_activities"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["active", "camp_occurrence_id", "cost_cents", "created_at", "date_occurs", "description", "id", "updated_at"]
  end
end
