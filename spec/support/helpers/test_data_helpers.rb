# frozen_string_literal: true

# Helper methods for managing test data

module TestDataHelpers
  # Create basic test data needed for most tests
  def setup_basic_test_data
    # Create genders if they don't exist
    Gender.find_or_create_by(name: 'Female') { |g| g.description = 'Female' }
    Gender.find_or_create_by(name: 'Male') { |g| g.description = 'Male' }
    Gender.find_or_create_by(name: 'Non-binary') { |g| g.description = 'Non-binary' }

    # Create demographics if they don't exist
    Demographic.find_or_create_by(name: 'Test Demographic') { |d| d.description = 'Test Description'; d.protected = false }
    Demographic.find_or_create_by(name: 'Other') { |d| d.description = 'Other demographic option'; d.protected = true }
  end

  # Clean up test data
  def cleanup_test_data
    # This is handled by database_cleaner, but can be customized if needed
  end

  # Generate realistic test dates
  def future_camp_dates(weeks_from_now: 12)
    start_date = weeks_from_now.weeks.from_now
    {
      application_open: start_date - 20.weeks,
      application_close: start_date - 4.weeks,
      priority: start_date - 12.weeks,
      application_materials_due: start_date - 8.weeks,
      camper_acceptance_due: start_date - 6.weeks,
      session_begin: start_date,
      session_end: start_date + 1.week
    }
  end
end

RSpec.configure do |config|
  config.include TestDataHelpers

  config.before(:suite) do
    # Setup basic test data once before the suite runs
    Gender.find_or_create_by(name: 'Female') { |g| g.description = 'Female' }
    Gender.find_or_create_by(name: 'Male') { |g| g.description = 'Male' }
    Demographic.find_or_create_by(name: 'Test Demographic') { |d| d.description = 'Test Description'; d.protected = false }
    Demographic.find_or_create_by(name: 'Other') { |d| d.description = 'Other demographic option'; d.protected = true }
  end
end
