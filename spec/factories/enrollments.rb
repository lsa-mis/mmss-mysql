# == Schema Information
#
# Table name: enrollments
#
#  id                            :bigint           not null, primary key
#  user_id                       :bigint           not null
#  international                 :boolean          default(FALSE), not null
#  high_school_name              :string(255)      not null
#  high_school_address1          :string(255)      not null
#  high_school_address2          :string(255)
#  high_school_city              :string(255)      not null
#  high_school_state             :string(255)
#  high_school_non_us            :string(255)
#  high_school_postalcode        :string(255)
#  high_school_country           :string(255)      not null
#  year_in_school                :string(255)      not null
#  anticipated_graduation_year   :string(255)      not null
#  room_mate_request             :string(255)
#  personal_statement            :text(65535)      not null
#  notes                         :text(65535)
#  application_status            :string(255)
#  offer_status                  :string(255)
#  partner_program               :string(255)
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  campyear                      :integer
#  application_deadline          :date
#  application_status_updated_on :date
#  uniqname                      :string(255)
#  camp_doc_form_completed       :boolean          default(FALSE)
#  application_fee_required      :boolean          default(TRUE), not null
#
FactoryBot.define do
  factory :enrollment do
    association :user

    international { false }
    high_school_name { Faker::Educator.university }
    high_school_address1 { Faker::Address.street_address }
    high_school_address2 { [nil, Faker::Address.secondary_address].sample }
    high_school_city { Faker::Address.city }
    high_school_state { Faker::Address.state_abbr }
    high_school_non_us { nil }
    high_school_postalcode { Faker::Address.zip_code }
    high_school_country { 'US' }

    year_in_school { ['Freshman', 'Sophomore', 'Junior', 'Senior'].sample }
    anticipated_graduation_year { (Date.current.year + rand(1..4)).to_s }
    room_mate_request { [nil, Faker::Name.name].sample }
    personal_statement { Faker::Lorem.paragraph_by_chars(number: 150) }
    notes { nil }

    application_status { nil }
    offer_status { nil }
    partner_program { nil }
    campyear { Date.current.year }
    application_deadline { nil }
    application_status_updated_on { nil }
    uniqname { nil }
    camp_doc_form_completed { false }
    application_fee_required { true }

    # Attach a transcript file
    after(:build) do |enrollment|
      link_to_default_transcript = "#{Rails.root}/spec/files/test.pdf"
      enrollment.transcript.attach(
        io: File.open(link_to_default_transcript),
        filename: 'transcript.pdf',
        content_type: 'application/pdf'
      )
    end

    trait :international do
      international { true }
      high_school_country { Faker::Address.country_code }
      high_school_state { nil }
      high_school_non_us { Faker::Address.state }
    end

    trait :domestic do
      international { false }
      high_school_country { 'US' }
      high_school_state { Faker::Address.state_abbr }
      high_school_non_us { nil }
    end

    trait :with_partner_program do
      partner_program { ['Partner A', 'Partner B', 'Partner C'].sample }
    end

    trait :application_complete do
      application_status { 'application complete' }
      application_status_updated_on { Date.current }
    end

    trait :offered do
      application_status { 'offered' }
      offer_status { 'offered' }
      application_status_updated_on { Date.current }
      application_deadline { 30.days.from_now }
    end

    trait :accepted do
      application_status { 'offer accepted' }
      offer_status { 'accepted' }
      application_status_updated_on { Date.current }
    end

    trait :declined do
      application_status { 'offer declined' }
      offer_status { 'declined' }
      application_status_updated_on { Date.current }
    end

    trait :enrolled do
      application_status { 'enrolled' }
      offer_status { 'accepted' }
      camp_doc_form_completed { true }
      application_status_updated_on { Date.current }
    end

    trait :rejected do
      application_status { 'rejected' }
      application_status_updated_on { Date.current }
    end

    trait :waitlisted do
      application_status { 'waitlisted' }
      application_status_updated_on { Date.current }
    end

    trait :with_student_packet do
      after(:create) do |enrollment|
        link_to_default_pdf = "#{Rails.root}/spec/files/test.pdf"
        enrollment.student_packet.attach(
          io: File.open(link_to_default_pdf),
          filename: 'student_packet.pdf',
          content_type: 'application/pdf'
        )
      end
    end

    trait :with_vaccine_record do
      after(:create) do |enrollment|
        link_to_default_pdf = "#{Rails.root}/spec/files/test.pdf"
        enrollment.vaccine_record.attach(
          io: File.open(link_to_default_pdf),
          filename: 'vaccine_record.pdf',
          content_type: 'application/pdf'
        )
      end
    end

    trait :with_uniqname do
      sequence(:uniqname) { |n| "student#{n}" }
    end

    trait :with_financial_aid do
      after(:create) do |enrollment|
        create(:financial_aid, enrollment: enrollment)
      end
    end

    trait :with_recommendation do
      after(:create) do |enrollment|
        create(:recommendation, enrollment: enrollment)
      end
    end
  end
end
