# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeedbackMailer, type: :mailer do
  let(:user) { create(:user, email: 'submitter@example.com') }
  let(:feedback) { create(:feedback, user: user, genre: 'page_error', message: 'The page crashed when I clicked submit.') }

  describe '#feedback_email' do
    let(:mail) { described_class.with(feedback: feedback).feedback_email }

    it 'renders the headers' do
      expect(mail.subject).to eq("Feedback from #{user.email}")
      expect(mail.to).to eq(['mmss-support@umich.edu'])
      expect(mail.from).to include('no-reply@math.lsa.umich.edu')
    end

    it 'renders the body with sender email' do
      expect(mail.body.encoded).to include(user.email)
    end

    it 'renders the body with feedback genre' do
      expect(mail.body.encoded).to include(feedback.genre)
    end

    it 'renders the body with feedback message' do
      expect(mail.body.encoded).to include(feedback.message)
    end

    it 'delivers successfully' do
      expect {
        mail.deliver_now
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end

  describe 'email content for different genres' do
    %w[page_error layout_issue suggestion].each do |genre|
      it "includes genre #{genre} in the email" do
        fb = create(:feedback, user: user, genre: genre, message: 'Test message')
        mail = described_class.with(feedback: fb).feedback_email
        expect(mail.body.encoded).to include(genre)
        expect(mail.body.encoded).to include('Test message')
      end
    end
  end
end
