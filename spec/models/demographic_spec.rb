# frozen_string_literal: true

# == Schema Information
#
# Table name: demographics
#
#  id          :bigint           not null, primary key
#  name        :string(255)      not null
#  description :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  protected   :boolean          default(FALSE)
#
require 'rails_helper'

RSpec.describe Demographic, type: :model do
  describe 'validations' do
    subject { build(:demographic) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_uniqueness_of(:description).case_insensitive }

    it 'rejects duplicate names after normalization (strips and titleizes)' do
      create(:demographic, name: 'Pacific Islander', description: 'First unique description')
      duplicate = build(:demographic, name: '  pacific islander  ', description: 'Second unique description')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end
    it { is_expected.to validate_length_of(:description).is_at_most(2250) }
  end

  describe 'normalization' do
    it 'strips and titleizes name before validation' do
      demographic = build(:demographic, name: '  african american  ')
      demographic.valid?
      expect(demographic.name).to eq('African American')
    end
  end

  describe 'name_format' do
    it 'rejects names containing punctuation' do
      # Hyphens are removed by titleize; use punctuation that survives normalization.
      demographic = build(:demographic, name: 'X@Y')
      expect(demographic).not_to be_valid
      expect(demographic.errors[:name]).to include('cannot contain punctuation')
    end

    it 'rejects names with consecutive spaces' do
      demographic = build(:demographic, name: 'Foo  Bar')
      expect(demographic).not_to be_valid
      expect(demographic.errors[:name]).to include('cannot contain consecutive spaces')
    end
  end

  describe '.modifiable' do
    it 'returns only non-protected rows' do
      regular = create(:demographic)
      protected_row = create(:demographic, :protected, name: 'Protected Option', description: 'Protected demographic description')

      expect(Demographic.modifiable).to include(regular)
      expect(Demographic.modifiable).not_to include(protected_row)
    end
  end

  describe '#destroy' do
    it 'blocks deletion when protected' do
      demographic = create(:demographic, :protected)
      expect(demographic.destroy).to be false
      expect(demographic.errors[:base]).to include('Cannot delete protected demographic options')
      expect(described_class.exists?(demographic.id)).to be true
    end

    it 'allows deletion when not protected' do
      demographic = create(:demographic)
      expect { demographic.destroy! }.to change(described_class, :count).by(-1)
    end
  end

  it_behaves_like 'a model with timestamps'
end
