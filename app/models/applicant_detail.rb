# == Schema Information
#
# Table name: applicant_details
#
#  id                 :bigint           not null, primary key
#  user_id            :bigint           not null
#  firstname          :string(255)      not null
#  middlename         :string(255)
#  lastname           :string(255)      not null
#  gender             :string(255)
#  us_citizen         :boolean          default(FALSE), not null
#  demographic        :string(255)
#  birthdate          :date             not null
#  diet_restrictions  :text(65535)
#  shirt_size         :string(255)
#  address1           :string(255)      not null
#  address2           :string(255)
#  city               :string(255)      not null
#  state              :string(255)      not null
#  state_non_us       :string(255)
#  postalcode         :string(255)      not null
#  country            :string(255)      not null
#  phone              :string(255)      not null
#  parentname         :string(255)      not null
#  parentaddress1     :string(255)
#  parentaddress2     :string(255)
#  parentcity         :string(255)
#  parentstate        :string(255)
#  parentstate_non_us :string(255)
#  parentzip          :string(255)
#  parentcountry      :string(255)
#  parentphone        :string(255)      not null
#  parentworkphone    :string(255)
#  parentemail        :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  demographic_other  :string(255)
#
class ApplicantDetail < ApplicationRecord
  belongs_to :user, required: true, inverse_of: :applicant_detail
  belongs_to :demographic_record, class_name: 'Demographic',
                                  foreign_key: 'demographic',
                                  optional: true

  validates :user_id, uniqueness: true
  validates :firstname, presence: true
  validates :lastname, presence: true
  # validates :us_citizen, presence: true
  validates :gender, presence: true
  validates :birthdate, presence: true
  validates :shirt_size, presence: true
  validates :demographic, presence: true
  validates :address1, presence: true
  validates :city, presence: true
  validates :state, presence: { message: "needs to be selected or if you are
                                          outside of the US select *Non-US*" }
  validates :postalcode, presence: true
  validates :country, presence: true
  validates :phone, presence: true,
                    format: { with: /\A(\+|00)?[0-9][0-9 \-?().]{7,}\z/, message: 'number format is incorrect' }
  validates :parentname, presence: true
  validates :parentphone, presence: true,
                          format: { with: /\A(\+|00)?[0-9][0-9 \-?().]{7,}\z/, message: 'number format is incorrect' }
  validates :parentemail, presence: true, length: { maximum: 255 },
                          format: { with: URI::MailTo::EMAIL_REGEXP, message: 'only allows valid emails' }
  validate :parentemail_not_user_email
  validate :demographic_other_if_other_selected

  scope :current_camp_enrolled, -> { where('user_id IN (?)', Enrollment.enrolled.pluck(:user_id)) }

  before_save :clear_demographic_other_if_not_other

  def full_name
    "#{lastname}, #{firstname}"
  end

  def applicant_email
    User.find(user_id).email
  end

  def full_name_and_email
    "#{full_name} - #{applicant_email}"
  end

  def gender_name
    Gender.find(gender).name
  end

  def demographic_name
    demographic_record&.name || 'None Selected'
  end

  def parentemail_not_user_email
    return true unless user.email == parentemail

    errors.add(:base, "Parent/Guardian email should be different than the applicant's email")
  end

  def self.ransackable_associations(auth_object = nil)
    ['user']
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[address1 address2 birthdate city country created_at demographic diet_restrictions
       firstname gender id lastname middlename parentaddress1 parentaddress2 parentcity parentcountry parentemail parentname parentphone parentstate parentstate_non_us parentworkphone parentzip phone postalcode shirt_size state state_non_us updated_at us_citizen user_id]
  end

  def formatted_demographic
    if demographic_name == 'Other' && demographic_other.present?
      "#{demographic_name} - #{demographic_other}"
    else
      demographic_name
    end
  end

  private

  def demographic_other_if_other_selected
    if demographic.present? && Demographic.find(demographic).name.downcase == 'other' && demographic_other.blank?
      errors.add(:demographic_other, "must be specified when 'Other' is selected")
    end
  end

  def clear_demographic_other_if_not_other
    return unless demographic.present? && Demographic.find(demographic).name.downcase != 'other'

    self.demographic_other = nil
  end
end
