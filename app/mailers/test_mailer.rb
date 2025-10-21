# frozen_string_literal: true

class TestMailer < ApplicationMailer
  def test_email(to_email)
    @timestamp = Time.current
    @environment = Rails.env

    mail(
      to: to_email,
      subject: "Test Email from MMSS (#{@environment})"
    )
  end
end
