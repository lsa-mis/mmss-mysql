namespace :email do
  desc "Send a test email to the specified address"
  task :test, [:email] => :environment do |t, args|
    if args[:email].blank?
      puts "Please provide an email address: rake email:test[your@email.com]"
      exit 1
    end

    begin
      TestMailer.test_email(args[:email]).deliver_now
      puts "Test email sent successfully to #{args[:email]}"
    rescue => e
      puts "Failed to send test email: #{e.message}"
      exit 1
    end
  end
end
