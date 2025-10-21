# frozen_string_literal: true

FactoryBot.define do
  factory :recupload do
    association :recommendation

    after(:build) do |recupload|
      link_to_default_pdf = "#{Rails.root}/spec/files/test.pdf"
      recupload.letter.attach(
        io: File.open(link_to_default_pdf),
        filename: 'recommendation_letter.pdf',
        content_type: 'application/pdf'
      )
    end
  end
end
