class DeviseMailerPreview < ActionMailer::Preview
  def password_change
    # Create a test user
    user = User.first || User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    # Call the Devise mailer with the test user
    Devise::Mailer.password_change(user)
  end

  def reset_password_instructions
    # Create a test user
    user = User.first || User.create!(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    # Generate a reset password token
    token = Devise.token_generator.generate(User, :reset_password_token)
    user.reset_password_token = token[0]
    user.reset_password_sent_at = Time.now.utc
    user.save!

    # Call the Devise mailer with the test user and token
    Devise::Mailer.reset_password_instructions(user, token[0])
  end
end
