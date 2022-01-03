# == Schema Information
#
# Table name: camp_occurrences
#
#  id                    :bigint           not null, primary key
#  camp_configuration_id :bigint           not null
#  description           :string           not null
#  begin_date            :date             not null
#  end_date              :date             not null
#  active                :boolean          default(FALSE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  cost_cents            :integer
#
class CampOccurrence < ApplicationRecord
  include MoneyRails::ActionViewExtension
  belongs_to :camp_configuration
  has_many :activities, dependent: :destroy
  has_many :courses, dependent: :destroy

  has_many :session_activities
  has_many :enrollments, through: :session_activities

  has_many :session_assignments, dependent: :destroy

  validates :description, presence: true
  validates :begin_date, presence: true, format: { with: ConstantData::VALID_DATE_REGEX }
  validates :end_date, presence: true, format: { with: ConstantData::VALID_DATE_REGEX }
  validates :cost_cents, presence: true, numericality: { only_integer: true }

  monetize :cost_cents

  scope :active, -> do
    CampOccurrence.table_exists? ? where(active: true).order(description: :asc) : {}
  end
  scope :no_any_session, -> do
    CampOccurrence.table_exists? ? where.not(description: "Any Session") : {}
  end

  scope :active_no_any_session, -> do
    CampOccurrence.table_exists? ? CampOccurrence.where(active: true).where.not(description: "Any Session").order(description: :asc) : {}
  end

  scope :session_description, ->(description="") { where(description: description).active.first}

  scope :camp_occurrence_filter, -> do
    CampOccurrence.table_exists? ? CampOccurrence.order(begin_date: :desc).no_any_session : {}
  end

  def description_with_date
    if description == "Any Session"
      "#{description}"
    else
      "#{description} -- #{begin_date} until #{end_date}"
    end
  end

  def description_with_date_and_price
    if description == "Any Session"
      "#{description}"
    else
      "#{description} -- #{begin_date} until #{end_date} -- #{humanized_money_with_symbol(self.cost)}" 
    end
  end

  def display_name
    "#{self.description} - #{self.begin_date} to #{self.end_date}" # or whatever column you want
  end

end
