require 'rails_helper'

RSpec.describe Course, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:camp_occurrence) }
    it { is_expected.to have_many(:course_preferences).dependent(:destroy) }
    it { is_expected.to have_many(:course_assignments).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:course) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:available_spaces) }
    it { is_expected.to validate_numericality_of(:available_spaces).is_greater_than_or_equal_to(0) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      course = build(:course)
      expect(course).to be_valid
    end

    it 'creates open course using trait' do
      course = create(:course, :open)
      expect(course.status).to eq('open')
    end

    it 'creates closed course using trait' do
      course = create(:course, :closed)
      expect(course.status).to eq('closed')
    end

    it 'creates full course using trait' do
      course = create(:course, :full)
      expect(course.available_spaces).to eq(0)
      expect(course.status).to eq('closed')
    end
  end

  describe 'scopes' do
    let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let(:camp_occurrence) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let!(:current_course) { create(:course, camp_occurrence: camp_occurrence, status: 'open') }

    let(:old_camp_config) { create(:camp_configuration, camp_year: Date.current.year - 1) }
    let(:old_occurrence) { create(:camp_occurrence, camp_configuration: old_camp_config, active: false) }
    let!(:old_course) { create(:course, camp_occurrence: old_occurrence) }

    describe '.current_camp' do
      it 'returns courses for the current camp year' do
        expect(Course.current_camp).to include(current_course)
        expect(Course.current_camp).not_to include(old_course)
      end
    end

    describe '.open' do
      let!(:closed_course) { create(:course, camp_occurrence: camp_occurrence, status: 'closed') }

      it 'returns only open courses' do
        expect(Course.open).to include(current_course)
        expect(Course.open).not_to include(closed_course)
      end
    end
  end

  describe '#display_name' do
    let(:course) { build(:course, title: 'Introduction to Physics') }

    it 'returns the title as display name' do
      expect(course.display_name).to eq('Introduction to Physics')
    end
  end

  describe '#open_spaces' do
    let(:course) { create(:course, available_spaces: 10) }

    context 'with no assignments' do
      it 'returns available spaces' do
        expect(course.open_spaces).to eq(10)
      end
    end

    context 'with assignments' do
      before do
        create_list(:course_assignment, 3, course: course, wait_list: false)
      end

      it 'returns available spaces minus assignments' do
        expect(course.open_spaces).to eq(7)
      end
    end

    context 'with waitlisted assignments' do
      before do
        create_list(:course_assignment, 2, course: course, wait_list: false)
        create_list(:course_assignment, 3, course: course, wait_list: true)
      end

      it 'does not count waitlisted assignments' do
        expect(course.open_spaces).to eq(8)
      end
    end
  end

  it_behaves_like 'a model with timestamps'
end
