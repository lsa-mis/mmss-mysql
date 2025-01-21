# == Schema Information
#
# Table name: recuploads
#
#  id                :bigint           not null, primary key
#  letter            :text(65535)
#  authorname        :string(255)      not null
#  studentname       :string(255)      not null
#  recommendation_id :bigint           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
FactoryBot.define do
  factory :recupload do
    letter { 'Sample recommendation letter' }
    authorname { 'John Smith' }
    studentname { 'Jane Doe' }
    recommendation

    trait :with_pdf_letter do
      after(:build) do |recupload|
        recupload.recletter.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'samplerecletter.pdf')),
          filename: 'samplerecletter.pdf',
          content_type: 'application/pdf'
        )
      end
    end
  end
end
