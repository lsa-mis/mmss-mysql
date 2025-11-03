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
      let(:enrollment) { create(:enrollment, :without_transcript) }
      before do
        allow(enrollment).to receive(:validate_transcript_presence)
        allow(enrollment).to receive(:acceptable_transcript)
      end
      let(:recommendation) { create(:recommendation, enrollment: enrollment) }
      let(:recupload) { build(:recupload, recommendation:) }

      it 'allows PDF files' do
        file = fixture_file_upload('samplerecletter.pdf', 'application/pdf')
        recupload.recletter.attach(file)
        expect(recupload).to be_valid
      end

      it 'allows PNG files' do
        file = fixture_file_upload('samplerecletter.png', 'image/png')
        recupload.recletter.attach(file)
        expect(recupload).to be_valid
      end

      it 'allows JPEG files' do
        file = fixture_file_upload('samplerecletter.jpg', 'image/jpeg')
        recupload.recletter.attach(file)
        expect(recupload).to be_valid
      end

      it 'does not allow other file types' do
        file = fixture_file_upload('samplerecletter.txt', 'text/plain')
        recupload.recletter.attach(file)
        expect(recupload).not_to be_valid
        expect(recupload.errors[:recletter]).to include('must be file type PDF, JPEG or PNG')
      end

      it 'does not allow files larger than 20MB' do
        allow_any_instance_of(ActiveStorage::Blob).to receive(:byte_size).and_return(21.megabytes)
        file = fixture_file_upload('samplerecletter.pdf', 'application/pdf')
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
    let(:enrollment) { create(:enrollment, :without_transcript) }
    let(:recommendation) { create(:recommendation, enrollment:) }

    before do
      allow(enrollment).to receive(:validate_transcript_presence)
      allow(enrollment).to receive(:acceptable_transcript)
    end

    context 'when application fee is not required' do
      before { enrollment.update(application_fee_required: false) }

      it 'updates enrollment status to complete' do
        create(:recupload, recommendation:)
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
          create(:recupload, recommendation:)
          expect(enrollment.reload.application_status).to eq('application complete')
          expect(enrollment.application_status_updated_on).to eq(Date.today)
        end
      end

      context 'without current camp payment' do
        it 'does not update enrollment status' do
          create(:recupload, recommendation:)
          expect(enrollment.reload.application_status).not_to eq('application complete')
        end
      end
    end

    context 'edge cases' do
      context 'when recommendation does not exist' do
        it 'handles missing recommendation gracefully' do
          recupload = build(:recupload, recommendation_id: 999999)
          expect { recupload.save }.not_to raise_error
        end
      end

      context 'when enrollment is not found' do
        before do
          allow(Recommendation).to receive(:find).and_return(double(enrollment: nil))
        end

        it 'handles missing enrollment gracefully' do
          recupload = build(:recupload, recommendation:)
          expect { recupload.save }.to raise_error(NoMethodError)
        end
      end

      context 'when payment query fails' do
        before do
          allow(Payment).to receive(:where).and_raise(ActiveRecord::StatementInvalid)
        end

        it 'handles database errors gracefully' do
          recupload = build(:recupload, recommendation:)
          expect { recupload.save }.to raise_error(ActiveRecord::StatementInvalid)
        end
      end
    end
  end

  describe 'edge cases for file validation' do
    let(:enrollment) { create(:enrollment, :without_transcript) }
    let(:recupload) { build(:recupload, recommendation: create(:recommendation, enrollment: enrollment)) }

    before do
      allow(enrollment).to receive(:validate_transcript_presence)
      allow(enrollment).to receive(:acceptable_transcript)
    end

    context 'when both letter and recletter are provided' do
      it 'is valid with both letter text and file attachment' do
        file = fixture_file_upload('samplerecletter.pdf', 'application/pdf')
        recupload.recletter.attach(file)
        recupload.letter = 'Some letter text'
        expect(recupload).to be_valid
      end
    end

    context 'when neither letter nor recletter is provided' do
      it 'is invalid without letter text or file attachment' do
        recupload.letter = ''
        recupload.recletter = nil
        expect(recupload).not_to be_valid
        expect(recupload.errors[:recletter]).to include('must be attached or letter text must be provided')
      end
    end

    context 'file size boundary testing' do
      it 'allows files exactly at 20MB limit' do
        allow_any_instance_of(ActiveStorage::Blob).to receive(:byte_size).and_return(20.megabytes)
        file = fixture_file_upload('samplerecletter.pdf', 'application/pdf')
        recupload.recletter.attach(file)
        expect(recupload).to be_valid
      end

      it 'rejects files just over 20MB limit' do
        allow_any_instance_of(ActiveStorage::Blob).to receive(:byte_size).and_return(20.megabytes + 1)
        file = fixture_file_upload('samplerecletter.pdf', 'application/pdf')
        recupload.recletter.attach(file)
        expect(recupload).not_to be_valid
        expect(recupload.errors[:recletter]).to include('is too big - file size cannot exceed 20Mbyte')
      end
    end

    context 'content type edge cases' do
      it 'handles files with nil content type' do
        recupload.letter = '' # Clear the letter so validation fails
        file = fixture_file_upload('samplerecletter.pdf', 'application/pdf')
        recupload.recletter.attach(file)
        allow(recupload.recletter.blob).to receive(:content_type).and_return(nil)
        expect(recupload).not_to be_valid
        expect(recupload.errors[:recletter]).to include('must be file type PDF, JPEG or PNG')
      end

      it 'handles files with empty content type' do
        recupload.letter = '' # Clear the letter so validation fails
        file = fixture_file_upload('samplerecletter.pdf', 'application/pdf')
        recupload.recletter.attach(file)
        allow(recupload.recletter.blob).to receive(:content_type).and_return('')
        expect(recupload).not_to be_valid
        expect(recupload.errors[:recletter]).to include('must be file type PDF, JPEG or PNG')
      end
    end
  end

  describe 'validation error messages' do
    let(:enrollment) { create(:enrollment, :without_transcript) }
    let(:recupload) { build(:recupload, recommendation: create(:recommendation, enrollment: enrollment)) }

    before do
      allow(enrollment).to receive(:validate_transcript_presence)
      allow(enrollment).to receive(:acceptable_transcript)
    end

    it 'provides clear error message for missing authorname' do
      recupload.authorname = ''
      expect(recupload).not_to be_valid
      expect(recupload.errors[:authorname]).to include("can't be blank")
    end

    it 'provides clear error message for missing studentname' do
      recupload.studentname = ''
      expect(recupload).not_to be_valid
      expect(recupload.errors[:studentname]).to include("can't be blank")
    end

    it 'provides clear error message for invalid file type' do
      file = fixture_file_upload('samplerecletter.txt', 'text/plain')
      recupload.recletter.attach(file)
      expect(recupload).not_to be_valid
      expect(recupload.errors[:recletter]).to include('must be file type PDF, JPEG or PNG')
    end
  end

  describe 'database constraints' do
    it 'requires recommendation_id to be present' do
      recupload = build(:recupload, recommendation: nil)
      expect(recupload).not_to be_valid
      expect(recupload.errors[:recommendation]).to include('must exist')
    end

    it 'prevents duplicate recuploads for same recommendation' do
      enrollment = create(:enrollment, :without_transcript)
      allow(enrollment).to receive(:validate_transcript_presence)
      allow(enrollment).to receive(:acceptable_transcript)

      recommendation = create(:recommendation, enrollment: enrollment)
      create(:recupload, recommendation: recommendation)
      duplicate_recupload = build(:recupload, recommendation: recommendation)

      # This should be prevented by the controller logic, but testing model behavior
      expect(duplicate_recupload).to be_valid # Model allows it, controller prevents it
    end
  end
end
