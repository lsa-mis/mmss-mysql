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
  options.add_argument('--headless=new') # Use new headless mode
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')
  # Anti-detection options to reduce reCAPTCHA triggers
  options.add_argument('--disable-blink-features=AutomationControlled')
  options.add_argument('--disable-extensions')
  options.add_argument('--disable-plugins-discovery')
  options.add_argument('--start-maximized')
  options.add_experimental_option('excludeSwitches', ['enable-automation'])
  options.add_experimental_option('useAutomationExtension', false)
  # Set a more realistic user agent
  options.add_argument('--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36')

  driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  
  # Remove webdriver property to avoid detection
  driver.browser.execute_cdp('Page.addScriptToEvaluateOnNewDocument', source: "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
  
  driver
end

Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')
  # Anti-detection options to reduce reCAPTCHA triggers
  options.add_argument('--disable-blink-features=AutomationControlled')
  options.add_argument('--disable-extensions')
  options.add_argument('--disable-plugins-discovery')
  options.add_argument('--start-maximized')
  options.add_experimental_option('excludeSwitches', ['enable-automation'])
  options.add_experimental_option('useAutomationExtension', false)
  # Set a more realistic user agent
  options.add_argument('--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36')

  driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  
  # Remove webdriver property to avoid detection
  driver.browser.execute_cdp('Page.addScriptToEvaluateOnNewDocument', source: "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
  
  driver
end
