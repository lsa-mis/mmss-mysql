# frozen_string_literal: true

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
# Indexes
#
#  index_recuploads_on_recommendation_id  (recommendation_id)
#
# Foreign Keys
#
#  fk_rails_...  (recommendation_id => recommendations.id)
#
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
