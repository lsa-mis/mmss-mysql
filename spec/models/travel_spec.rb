# frozen_string_literal: true

# == Schema Information
#
# Table name: travels
#
#  id                :bigint           not null, primary key
#  enrollment_id     :bigint           not null
#  arrival_transport :string(255)
#  arrival_carrier   :string(255)
#  arrival_route_num :string(255)
#  note              :text(65535)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  arrival_date      :date
#  arrival_time      :time
#  depart_transport  :string(255)
#  depart_route_num  :string(255)
#  depart_date       :date
#  depart_time       :time
#  depart_carrier    :string(255)
#  arrival_session   :string(255)
#  depart_session    :string(255)
#
# Indexes
#
#  index_travels_on_enrollment_id  (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (enrollment_id => enrollments.id)
#
require 'rails_helper'

RSpec.describe Travel, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:enrollment) }
  end

  describe 'validations' do
    subject { build(:travel) }

    it { is_expected.to validate_presence_of(:arrival_transport) }
    it { is_expected.to validate_presence_of(:depart_transport) }
    it { is_expected.to validate_presence_of(:arrival_session) }
    it { is_expected.to validate_presence_of(:depart_session) }
  end

  describe '.ransackable_attributes' do
    it 'lists attributes allowed for admin search' do
      attrs = described_class.ransackable_attributes
      expect(attrs).to include('arrival_transport', 'depart_transport', 'enrollment_id', 'note')
    end

    it 'accepts optional auth object' do
      expect { described_class.ransackable_attributes(nil) }.not_to raise_error
    end
  end

  describe '.ransackable_associations' do
    it 'includes enrollment' do
      expect(described_class.ransackable_associations).to eq(['enrollment'])
    end
  end

  it_behaves_like 'a model with timestamps'
end
