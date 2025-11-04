# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecuploadMailer, type: :mailer do
  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, user: user) }
  let(:recommendation) { create(:recommendation, enrollment: enrollment) }
  let(:recupload) { create(:recupload, recommendation: recommendation) }

  describe '#received_email' do
    let(:mail) { RecuploadMailer.with(recupload: recupload).received_email }

    it 'renders the headers' do
      expect(mail.subject).to eq("University of Michigan - Michigan Math and Science Scholars: Recommendation for #{user.applicant_detail.firstname} #{user.applicant_detail.lastname}")
      expect(mail.to).to eq([recommendation.email])
      expect(mail.from).to eq(['no-reply@math.lsa.umich.edu'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include('recommendation')
      expect(mail.body.encoded).to include(user.applicant_detail.firstname)
      expect(mail.body.encoded).to include(user.applicant_detail.lastname)
    end

    it 'includes the recommendation details' do
      expect(mail.body.encoded).to include(recommendation.firstname)
      expect(mail.body.encoded).to include(recommendation.lastname)
    end
  end

  describe '#applicant_received_email' do
    let(:mail) { RecuploadMailer.with(recupload: recupload).applicant_received_email }

    it 'renders the headers' do
      expect(mail.subject).to eq("University of Michigan - Michigan Math and Science Scholars: Recommendation received for #{user.applicant_detail.firstname} #{user.applicant_detail.lastname}")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(['no-reply@math.lsa.umich.edu'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include('recommendation')
      expect(mail.body.encoded).to include(user.applicant_detail.firstname)
      expect(mail.body.encoded).to include(user.applicant_detail.lastname)
    end

    it 'sends to the correct student email' do
      expect(mail.to).to eq([user.email])
    end
  end

  describe 'email delivery' do
    it 'delivers received_email' do
      expect {
        RecuploadMailer.with(recupload: recupload).received_email.deliver_now
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'delivers applicant_received_email' do
      expect {
        RecuploadMailer.with(recupload: recupload).applicant_received_email.deliver_now
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'delivers both emails when called together' do
      expect {
        RecuploadMailer.with(recupload: recupload).received_email.deliver_now
        RecuploadMailer.with(recupload: recupload).applicant_received_email.deliver_now
      }.to change { ActionMailer::Base.deliveries.count }.by(2)
    end
  end

  describe 'error handling' do
    context 'when recommendation is not found' do
      before do
        allow(Recommendation).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it 'raises error for received_email' do
        expect {
          RecuploadMailer.with(recupload: recupload).received_email
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'raises error for applicant_received_email' do
        expect {
          RecuploadMailer.with(recupload: recupload).applicant_received_email
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when student details are missing' do
      let(:enrollment_without_applicant) { create(:enrollment, user: user) }
      let(:recommendation_without_applicant) { create(:recommendation, enrollment: enrollment_without_applicant) }
      let(:recupload_without_applicant) { create(:recupload, recommendation: recommendation_without_applicant) }

      before do
        allow(user).to receive(:applicant_detail).and_return(nil)
      end

      it 'handles missing applicant details gracefully' do
        expect {
          RecuploadMailer.with(recupload: recupload_without_applicant).received_email
        }.not_to raise_error
      end
    end
  end

  describe 'email content validation' do
    let(:received_mail) { RecuploadMailer.with(recupload: recupload).received_email }
    let(:applicant_mail) { RecuploadMailer.with(recupload: recupload).applicant_received_email }

    it 'includes proper salutation in received_email' do
      expect(received_mail.body.encoded).to include(recommendation.firstname)
    end

    it 'includes proper salutation in applicant_received_email' do
      expect(applicant_mail.body.encoded).to include(user.applicant_detail.firstname)
    end

    it 'includes proper contact information in both emails' do
      expect(received_mail.body.encoded).to include('mmss@umich.edu')
      expect(applicant_mail.body.encoded).to include('mmss@umich.edu')
    end
  end

  describe 'email formatting' do
    let(:received_mail) { RecuploadMailer.with(recupload: recupload).received_email }
    let(:applicant_mail) { RecuploadMailer.with(recupload: recupload).applicant_received_email }

    it 'has proper content type for received_email' do
      expect(received_mail.content_type).to include('multipart/related')
    end

    it 'has proper content type for applicant_received_email' do
      expect(applicant_mail.content_type).to include('multipart/related')
    end

    it 'has proper encoding' do
      expect(received_mail.charset).to eq('UTF-8')
      expect(applicant_mail.charset).to eq('UTF-8')
    end
  end
end
