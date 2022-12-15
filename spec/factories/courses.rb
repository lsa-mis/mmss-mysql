# == Schema Information
#
# Table name: courses
#
#  id                 :bigint           not null, primary key
#  camp_occurrence_id :bigint           not null
#  title              :string(255)
#  available_spaces   :integer
#  status             :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  faculty_uniqname   :string(255)
#  faculty_name       :string(255)
#
FactoryBot.define do
  factory :course do
    camp_occurrence { nil }
    title { "MyString" }
    available_spaces { 1 }
    status { "MyString" }
  end
end
