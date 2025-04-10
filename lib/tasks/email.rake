# frozen_string_literal: true

namespace :email do
  # Usage: rake email:test[your@email.com]
  # Note: If using zsh, wrap the email in quotes: rake 'email:test[your@email.com]'
  desc 'Send a test email to the specified address'
  task :test, [:email] => :environment do |_t, args|
    if args[:email].blank?
      puts 'Please provide an email address: rake email:test[your@email.com]'
      exit 1
    end

    begin
      TestMailer.test_email(args[:email]).deliver_now
      puts "Test email sent successfully to #{args[:email]}"
    rescue StandardError => e
      puts "Failed to send test email: #{e.message}"
      exit 1
    end
  end
end
