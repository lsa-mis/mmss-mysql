# frozen_string_literal: true

# == Schema Information
#
# Table name: campnotes
#
#  id         :bigint           not null, primary key
#  note       :string(255)
#  opendate   :datetime
#  closedate  :datetime
#  notetype   :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe Campnote, type: :model do
  describe 'validations' do
    subject { build(:campnote) }

    it { is_expected.to validate_presence_of(:note) }
    it { is_expected.to validate_presence_of(:notetype) }
    it { is_expected.to validate_presence_of(:opendate) }
    it { is_expected.to validate_presence_of(:closedate) }

    describe 'end_date_after_start_date validation' do
      context 'when closedate is before opendate' do
        let(:campnote) do
          build(:campnote,
            opendate: 2.weeks.from_now,
            closedate: 1.week.from_now
          )
        end

        it 'is invalid' do
          expect(campnote).not_to be_valid
          expect(campnote.errors[:closedate]).to include('must be after the start date')
        end
      end

      context 'when closedate is after opendate' do
        let(:campnote) do
          build(:campnote,
            opendate: 1.week.from_now,
            closedate: 2.weeks.from_now
          )
        end

        it 'is valid' do
          expect(campnote).to be_valid
        end
      end

      context 'when closedate equals opendate' do
        let(:opendate) { 1.week.from_now }
        let(:campnote) do
          build(:campnote,
            opendate: opendate,
            closedate: opendate
          )
        end

        it 'is valid' do
          expect(campnote).to be_valid
        end
      end

      context 'when dates are blank' do
        let(:campnote) { build(:campnote, opendate: nil, closedate: nil) }

        it 'does not add end_date_after_start_date error' do
          campnote.valid?
          expect(campnote.errors[:closedate]).not_to include('must be after the start date')
        end
      end
    end

    describe 'availability validator' do
      context 'when opendate overlaps with existing campnote' do
        let!(:existing_note) do
          create(:campnote,
            opendate: 1.week.from_now,
            closedate: 2.weeks.from_now
          )
        end

        let(:new_note) do
          build(:campnote,
            opendate: 1.week.from_now + 1.day,
            closedate: 3.weeks.from_now
          )
        end

        it 'is invalid' do
          expect(new_note).not_to be_valid
          expect(new_note.errors[:opendate]).to include('not available')
        end
      end

      context 'when closedate overlaps with existing campnote' do
        let!(:existing_note) do
          create(:campnote,
            opendate: 1.week.from_now,
            closedate: 2.weeks.from_now
          )
        end

        let(:new_note) do
          build(:campnote,
            opendate: 3.days.from_now,
            closedate: 1.week.from_now + 1.day
          )
        end

        it 'is invalid' do
          expect(new_note).not_to be_valid
          expect(new_note.errors[:closedate]).to include('not available')
        end
      end

      context 'when dates do not overlap with existing campnote' do
        let!(:existing_note) do
          create(:campnote,
            opendate: 1.week.from_now,
            closedate: 2.weeks.from_now
          )
        end

        let(:new_note) do
          build(:campnote,
            opendate: 3.weeks.from_now,
            closedate: 4.weeks.from_now
          )
        end

        it 'is valid' do
          expect(new_note).to be_valid
        end
      end

      context 'when updating an existing campnote' do
        let!(:existing_note) do
          create(:campnote,
            opendate: 1.week.from_now,
            closedate: 2.weeks.from_now
          )
        end

        let!(:other_note) do
          create(:campnote,
            opendate: 3.weeks.from_now,
            closedate: 4.weeks.from_now
          )
        end

        it 'does not conflict with itself' do
          existing_note.note = 'Updated note'
          expect(existing_note).to be_valid
        end

        it 'conflicts with other notes' do
          existing_note.opendate = 3.weeks.from_now + 1.day
          expect(existing_note).not_to be_valid
          expect(existing_note.errors[:opendate]).to include('not available')
        end
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      campnote = build(:campnote)
      expect(campnote).to be_valid
    end

    it 'creates a campnote with all required attributes' do
      campnote = create(:campnote)
      expect(campnote.note).to be_present
      expect(campnote.notetype).to be_present
      expect(campnote.opendate).to be_present
      expect(campnote.closedate).to be_present
    end
  end

  describe '.ransackable_attributes' do
    it 'returns the correct ransackable attributes' do
      expected_attributes = [
        'closedate',
        'created_at',
        'id',
        'note',
        'notetype',
        'opendate',
        'updated_at'
      ]
      expect(Campnote.ransackable_attributes).to match_array(expected_attributes)
    end
  end

  it_behaves_like 'a model with timestamps'
end
