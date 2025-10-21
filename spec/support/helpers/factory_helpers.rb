# frozen_string_literal: true

# Helper methods for working with factories in tests

module FactoryHelpers
  # Creates a complete enrollment with all required associations
  def create_complete_enrollment(attributes = {})
    user = attributes[:user] || create(:user)
    applicant_detail = create(:applicant_detail, user: user)

    # Ensure test seeds are loaded
    load_test_seeds_if_needed

    session_ids = CampOccurrence.active.pluck(:id).first(2)
    course_ids = Course.where(camp_occurrence_id: session_ids).pluck(:id).first(2)

    create(:enrollment,
      user: user,
      session_registration_ids: session_ids,
      course_registration_ids: course_ids,
      **attributes
    )
  end

  # Creates a user with applicant details
  def create_user_with_details(attributes = {})
    user = create(:user, attributes)
    create(:applicant_detail, user: user)
    user
  end

  # Ensures test seeds are loaded
  def load_test_seeds_if_needed
    return if @test_seeds_loaded

    load "#{Rails.root}/spec/test_seeds.rb" if Gender.count.zero?
    @test_seeds_loaded = true
  end

  # Creates a complete camp setup
  def create_camp_setup(year: 2025)
    camp_config = create(:camp_configuration, camp_year: year, active: true)
    session1 = create(:camp_occurrence,
      camp_configuration: camp_config,
      description: 'Session 1',
      active: true
    )
    session2 = create(:camp_occurrence,
      camp_configuration: camp_config,
      description: 'Session 2',
      active: true
    )

    # Create courses for each session
    3.times do
      create(:course, camp_occurrence: session1, status: 'open')
      create(:course, camp_occurrence: session2, status: 'open')
    end

    camp_config
  end
end

RSpec.configure do |config|
  config.include FactoryHelpers
end
