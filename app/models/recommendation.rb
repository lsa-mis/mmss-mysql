# == Schema Information
#
# Table name: recommendations
#
#  id                       :bigint           not null, primary key
#  enrollment_id            :bigint           not null
#  email                    :string           not null
#  lastname                 :string           not null
#  firstname                :string           not null
#  organization             :string
#  address1                 :string
#  address2                 :string
#  city                     :string
#  state                    :string
#  state_non_us             :string
#  postalcode               :string
#  country                  :string
#  phone_number             :string
#  best_contact_time        :string
#  submitted_recommendation :string
#  date_submitted           :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
class Recommendation < ApplicationRecord
  belongs_to :enrollment
  has_one :recupload, dependent: :destroy

  validates :email, presence: true, length: {maximum: 255},
                    format: {with: URI::MailTo::EMAIL_REGEXP, message: "only allows valid emails"}
  validates :firstname, presence: true
  validates :lastname, presence: true
  validates :organization, presence: true


  def full_name
    "#{firstname} #{lastname}"
  end

  def display_name
    "#{lastname}, #{firstname}"
  end

end
