# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecommendationMailer, type: :mailer do
  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, user: user) }
  let(:recommendation) { create(:recommendation, enrollment: enrollment, email: 'recommender@example.edu') }
  let(:mail) { described_class.with(recommendation: recommendation).request_email }

  describe '#request_email' do
    it 'renders the headers' do
      expect(mail.to).to eq(['recommender@example.edu'])
      expect(mail.subject).to eq("University of Michigan - Michigan Math and Science Scholars: Recommendation Request for #{user.applicant_detail.firstname} #{user.applicant_detail.lastname}")
      expect(mail.header['X-SMTPAPI'].value).to include('clicktrack')
    end

    it 'links the upload page with only the random token' do
      [mail.html_part, mail.text_part].each do |part|
        body = part.body.decoded
        expect(body).to include("/recuploads/new?token=#{recommendation.upload_token}")
        expect(body).not_to include('nGklDoc2egIkzFxr0U')
        expect(body).not_to include('hash=')
        expect(body).not_to include("id=#{user.applicant_detail.id}")
        expect(body).not_to include(CGI.escape(recommendation.email))
      end
    end

    it 'tells the recommender when the link expires' do
      expected = recommendation.upload_token_expires_at.to_date.strftime('%B %-d, %Y')

      expect(mail.html_part.body.decoded).to include(expected)
      expect(mail.text_part.body.decoded).to include(expected)
    end

    # EmailErrorHandler rescues mailer exceptions (and re-raises only when raise_delivery_errors
    # is on), so a tokenless recommendation produces a logged error and an unaddressed message
    # rather than an email with a broken link.
    it 'refuses to build a link for a recommendation without an active token' do
      recommendation.invalidate_upload_token!
      logged = []
      allow(Rails.logger).to receive(:error) { |msg| logged << msg }

      message = described_class.with(recommendation: recommendation).request_email.message

      expect(message.to).to be_nil
      expect(message.body.to_s).not_to include('recuploads/new')
      expect(logged.join("\n")).to include('no active upload token')
    end
  end
end
