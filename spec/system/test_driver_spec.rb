# frozen_string_literal: true

# Selenium 4.11+ includes Selenium Manager which automatically downloads and manages drivers.
# This spec only runs when DRIVER_TEST=1 to avoid launching Chrome during normal test runs.
# Run with: DRIVER_TEST=1 bundle exec rspec spec/system/test_driver_spec.rb

require "selenium-webdriver"

RSpec.describe "Chrome driver sanity check" do
  it "can hit Google and search", skip: "Set DRIVER_TEST=1 to run" do
    skip "Set DRIVER_TEST=1 to run" unless ENV["DRIVER_TEST"] == "1"

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--remote-allow-origins=*")

    driver = Selenium::WebDriver.for :chrome, options: options
    driver.navigate.to "http://www.google.com"
    element = driver.find_element(:name, "q")
    element.send_keys "Hello Selenium WebDriver!"
    element.submit
    puts driver.title
  end
end
