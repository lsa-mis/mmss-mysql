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
