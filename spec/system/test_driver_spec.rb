# frozen_string_literal: true

# Selenium 4.11+ includes Selenium Manager which automatically downloads and manages drivers.
# This file defines examples only when DRIVER_TEST=1 so normal runs do not skip or open Chrome.
# Run with: DRIVER_TEST=1 bundle exec rspec spec/system/test_driver_spec.rb

require "selenium-webdriver"

# Only register the example when DRIVER_TEST=1 so normal `rspec` runs stay clean (no pending skips).
# Run: DRIVER_TEST=1 bundle exec rspec spec/system/test_driver_spec.rb
RSpec.describe "Chrome driver sanity check" do
  if ENV["DRIVER_TEST"] == "1"
    it "can hit Google and search" do
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--disable-gpu")
      options.add_argument("--remote-allow-origins=*")

      driver = Selenium::WebDriver.for :chrome, options: options
      begin
        driver.navigate.to "https://www.google.com"
        element = driver.find_element(:name, "q")
        element.send_keys "Hello Selenium WebDriver!"
        element.submit
        expect(driver.title).to match(/Google/i)
      ensure
        driver.quit
      end
    end
  end
end
