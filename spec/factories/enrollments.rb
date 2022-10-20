# == Schema Information
#
# Table name: enrollments
#
#  id                          :bigint           not null, primary key
#  user_id                     :bigint           not null
#  international               :boolean          default(FALSE), not null
#  high_school_name            :string           not null
#  high_school_address1        :string           not null
#  high_school_address2        :string
#  high_school_city            :string           not null
#  high_school_state           :string
#  high_school_non_us          :string
#  high_school_postalcode      :string
#  high_school_country         :string           not null
#  year_in_school              :string           not null
#  anticipated_graduation_year :string           not null
#  room_mate_request           :string
#  personal_statement          :text             not null
#  notes                       :text
#  application_status          :string
#  offer_status                :string
#  partner_program             :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  campyear                    :integer
#  application_deadline        :date
#  application_status_updated_on :date
#
FactoryBot.define do
  factory :enrollment do
    association :user
    # international { false }
    high_school_name { Faker::University.name }
    high_school_address1 { Faker::Address.street_address}
    # high_school_address2 { "MyString" }
    high_school_city { Faker::Address.city }
    # high_school_state { "MyString" }
    # high_school_non_us { "MyString" }
    # high_school_postalcode { "MyString" }
    high_school_country { "US" }
    year_in_school { "Junior" }
    anticipated_graduation_year { "2023" }
    # room_mate_request { "MyString" }
    personal_statement { Faker::Lorem.paragraph_by_chars(number: 100, supplemental: false)  }
    # shirt_size { "MyString" }
    # notes { "MyText" }
    # application_status { "MyString" }
    # offer_status { "MyString" }
    # partner_program { "MyString" }
    campyear { 2022 }

    link_to_default_transcript = "#{Rails.root}/spec/files/test.pdf"
    transcript { Rack::Test::UploadedFile.new link_to_default_transcript, "application/pdf" }
  end
end
