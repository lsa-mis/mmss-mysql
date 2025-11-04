# frozen_string_literal: true

FactoryBot.define do
  factory :recupload do
    association :recommendation
    authorname { 'Dr. Test Author' }
    studentname { 'Test Student' }
    letter { 'This is a test recommendation letter.' }

    trait :with_file do
      after(:build) do |recupload|
        link_to_default_pdf = "#{Rails.root}/spec/files/test.pdf"
        recupload.recletter.attach(
          io: File.open(link_to_default_pdf),
          filename: 'recommendation_letter.pdf',
          content_type: 'application/pdf'
        )
      end
    end
  end
end
