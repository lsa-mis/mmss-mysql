# frozen_string_literal: true

# Capybara configuration for system tests
# This file configures Capybara and Selenium to work around compatibility issues

require 'capybara/rspec'
require 'selenium-webdriver'

# Configure Selenium to suppress logger initialization issues
# This works around a compatibility issue between selenium-webdriver versions
Selenium::WebDriver.logger.level = :error

# Configure Capybara
Capybara.default_driver = :rack_test
Capybara.javascript_driver = ENV['SHOW_BROWSER'] ? :selenium_chrome : :selenium_chrome_headless

# Configure Chrome options for headless mode
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
