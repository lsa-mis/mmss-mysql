# frozen_string_literal: true

# == Schema Information
#
# Table name: recuploads
#
#  id                :bigint           not null, primary key
#  letter            :text(65535)
#  authorname        :string(255)      not null
#  studentname       :string(255)      not null
#  recommendation_id :bigint           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
require 'rails_helper'

RSpec.describe Recupload, type: :model do
  let(:recommendation) { create(:recommendation) }

  describe 'validations' do
    it { should validate_presence_of(:authorname) }
    it { should validate_presence_of(:studentname) }

    describe 'recletter attachment' do
      let(:recupload) { build(:recupload, recommendation:) }

      it 'allows PDF files' do
        file = fixture_file_upload('spec/fixtures/files/samplerecletter.pdf', 'application/pdf')
        recupload.recletter.attach(file)
        expect(recupload).to be_valid
      end

      it 'allows PNG files' do
        file = fixture_file_upload('spec/fixtures/files/samplerecletter.png', 'image/png')
        recupload.recletter.attach(file)
        expect(recupload).to be_valid
      end

      it 'allows JPEG files' do
        file = fixture_file_upload('spec/fixtures/files/samplerecletter.jpg', 'image/jpeg')
        recupload.recletter.attach(file)
        expect(recupload).to be_valid
      end

      it 'does not allow other file types' do
        file = fixture_file_upload('spec/fixtures/files/samplerecletter.txt', 'text/plain')
        recupload.recletter.attach(file)
        expect(recupload).not_to be_valid
        expect(recupload.errors[:recletter]).to include('must be file type PDF, JPEG or PNG')
      end

      it 'does not allow files larger than 20MB' do
        allow_any_instance_of(ActiveStorage::Blob).to receive(:byte_size).and_return(21.megabytes)
        file = fixture_file_upload('spec/fixtures/files/samplerecletter.pdf', 'application/pdf')
        recupload.recletter.attach(file)
        expect(recupload).not_to be_valid
        expect(recupload.errors[:recletter]).to include('is too big - file size cannot exceed 20Mbyte')
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:recommendation) }
    it { should have_one_attached(:recletter) }
  end

  describe '#update_enrollment_status' do
    let(:enrollment) { create(:enrollment) }
    let(:recommendation) { create(:recommendation, enrollment:) }

    context 'when application fee is not required' do
      before { enrollment.update(application_fee_required: false) }

      it 'updates enrollment status to complete' do
        recupload = create(:recupload, recommendation:)
        expect(enrollment.reload.application_status).to eq('application complete')
        expect(enrollment.application_status_updated_on).to eq(Date.today)
      end
    end

    context 'when application fee is required' do
      before { enrollment.update(application_fee_required: true) }

      context 'with current camp payment' do
        before do
          create(:payment, user: enrollment.user,
                           transaction_status: '1', camp_year: CampConfiguration.active_camp_year)
        end

        it 'updates enrollment status to complete' do
          recupload = create(:recupload, recommendation:)
          expect(enrollment.reload.application_status).to eq('application complete')
          expect(enrollment.application_status_updated_on).to eq(Date.today)
        end
      end

      context 'without current camp payment' do
        it 'does not update enrollment status' do
          recupload = create(:recupload, recommendation:)
          expect(enrollment.reload.application_status).not_to eq('application complete')
        end
      end
    end
  end
end
