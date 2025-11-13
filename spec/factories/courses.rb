# frozen_string_literal: true

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
# Indexes
#
#  index_courses_on_camp_occurrence_id  (camp_occurrence_id)
#
# Foreign Keys
#
#  fk_rails_...  (camp_occurrence_id => camp_occurrences.id)
#
FactoryBot.define do
  factory :course do
    association :camp_occurrence

    title { "#{Faker::Educator.subject}: #{Faker::Educator.course_name}" }
    available_spaces { 16 }
    status { 'open' }
    faculty_name { Faker::Name.name }
    faculty_uniqname { Faker::Internet.username(specifier: faculty_name, separators: ['']) }

    trait :open do
      status { 'open' }
    end

    trait :closed do
      status { 'closed' }
    end

    trait :full do
      available_spaces { 0 }
      status { 'closed' }
    end

    trait :large_class do
      available_spaces { 25 }
    end

    trait :small_class do
      available_spaces { 8 }
    end

    trait :with_assignments do
      after(:create) do |course|
        create_list(:course_assignment, 3, course: course)
      end
    end
  end
end
