# == Schema Information
#
# Table name: enrollments
#
#  id                          :bigint           not null, primary key
#  user_id                     :bigint           not null
#  international               :boolean          default(FALSE), not null
#  high_school_name            :string(255)      not null
#  high_school_address1        :string(255)      not null
#  high_school_address2        :string(255)
#  high_school_city            :string(255)      not null
#  high_school_state           :string(255)
#  high_school_non_us          :string(255)
#  high_school_postalcode      :string(255)
#  high_school_country         :string(255)      not null
#  year_in_school              :string(255)      not null
#  anticipated_graduation_year :string(255)      not null
#  room_mate_request           :string(255)
#  personal_statement          :text(65535)      not null
#  notes                       :text(65535)
#  application_status          :string(255)
#  offer_status                :string(255)
#  partner_program             :string(255)
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  campyear                    :integer
#  application_deadline        :date
#
FactoryBot.define do
  factory :enrollment do
    user
    # international { false }
    high_school_name { "Academy of Smartness" }
    high_school_address1 { "345 Main Street" }
    # high_school_address2 { "MyString" }
    high_school_city { "Saline" }
    # high_school_state { "MyString" }
    # high_school_non_us { "MyString" }
    # high_school_postalcode { "MyString" }
    high_school_country { "US" }
    year_in_school { "Junior" }
    anticipated_graduation_year { "2018" }
    # room_mate_request { "MyString" }
    personal_statement { "I was born in a shed" }
    # shirt_size { "MyString" }
    # notes { "MyText" }
    # application_status { "MyString" }
    # offer_status { "MyString" }
    # partner_program { "MyString" }
  end
end
