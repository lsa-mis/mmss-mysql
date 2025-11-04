# frozen_string_literal: true

require "webdrivers"

# Webdrivers 5.3.1 supports the Chrome for Testing API (non-deprecated)
# It will automatically download the correct ChromeDriver version for your Chrome browser
# The gem handles Chrome version detection and uses the modern Chrome for Testing infrastructure

# Configure Chrome options
options = Selenium::WebDriver::Chrome::Options.new
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
options.add_argument("--disable-gpu")
options.add_argument("--remote-allow-origins=*")

# Webdrivers will automatically download the matching ChromeDriver using Chrome for Testing API
driver = Selenium::WebDriver.for :chrome, options: options
driver.navigate.to "http://www.google.com"
element = driver.find_element(:name, 'q')
element.send_keys "Hello Selenium WebDriver!"
element.submit
puts driver.title
