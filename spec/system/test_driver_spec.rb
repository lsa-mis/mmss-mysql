# frozen_string_literal: true

# Selenium 4.11+ includes Selenium Manager which automatically downloads and manages drivers
# No need for webdrivers gem - Selenium Manager handles ChromeDriver version detection
# and uses the Chrome for Testing infrastructure automatically

# Configure Chrome options
options = Selenium::WebDriver::Chrome::Options.new
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
options.add_argument("--disable-gpu")
options.add_argument("--remote-allow-origins=*")

# Selenium Manager automatically downloads the matching ChromeDriver
driver = Selenium::WebDriver.for :chrome, options: options
driver.navigate.to "http://www.google.com"
element = driver.find_element(:name, 'q')
element.send_keys "Hello Selenium WebDriver!"
element.submit
puts driver.title
