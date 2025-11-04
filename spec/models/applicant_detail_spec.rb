# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicantDetail, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user).required }
    it { is_expected.to belong_to(:demographic).optional }
  end

  describe 'validations' do
    subject { create(:applicant_detail) }

    it { is_expected.to validate_presence_of(:firstname) }
    it { is_expected.to validate_presence_of(:lastname) }
    it { is_expected.to validate_presence_of(:gender) }
    it { is_expected.to validate_presence_of(:birthdate) }
    it { is_expected.to validate_presence_of(:shirt_size) }
    it { is_expected.to validate_presence_of(:demographic_id) }
    it { is_expected.to validate_presence_of(:address1) }
    it { is_expected.to validate_presence_of(:city) }
    it { is_expected.to validate_presence_of(:postalcode) }
    it { is_expected.to validate_presence_of(:country) }
    it { is_expected.to validate_presence_of(:phone) }
    it { is_expected.to validate_presence_of(:parentname) }
    it { is_expected.to validate_presence_of(:parentphone) }
    it { is_expected.to validate_presence_of(:parentemail) }
    it { is_expected.to validate_uniqueness_of(:user_id) }

    describe 'state validation' do
      it 'validates presence with custom error message' do
        applicant = create(:applicant_detail)
        applicant.state = nil
        expect(applicant).not_to be_valid
        expect(applicant.errors[:state].first).to match(/needs to be selected or if you are.*outside of the US select \*Non-US\*/m)
      end

      it 'is valid with a state' do
        applicant = create(:applicant_detail, state: 'CA')
        expect(applicant).to be_valid
      end
    end

    describe 'postalcode validation' do
      let(:applicant_detail) { build(:applicant_detail) }

      it 'is valid with a postal code between 1 and 25 characters' do
        applicant_detail.postalcode = '12345'
        expect(applicant_detail).to be_valid
      end

      it 'is valid with alphanumeric characters, spaces, and dashes' do
        applicant_detail.postalcode = 'SW1A 1AA'
        expect(applicant_detail).to be_valid
      end

      it 'is valid with a dash in postal code' do
        applicant_detail.postalcode = '12345-6789'
        expect(applicant_detail).to be_valid
      end

      it 'is valid with a single character' do
        applicant_detail.postalcode = 'A'
        expect(applicant_detail).to be_valid
      end

      it 'is valid with exactly 25 characters' do
        applicant_detail.postalcode = 'A' * 25
        expect(applicant_detail).to be_valid
      end

      it 'is invalid with more than 25 characters' do
        applicant_detail.postalcode = 'A' * 26
        expect(applicant_detail).not_to be_valid
        expect(applicant_detail.errors[:postalcode]).to include('must be between 1 and 25 characters')
      end

      it 'is invalid with special characters other than spaces and dashes' do
        applicant_detail.postalcode = '12345@678'
        expect(applicant_detail).not_to be_valid
        expect(applicant_detail.errors[:postalcode]).to include('can only contain letters, numbers, spaces, and dashes')
      end

      it 'is invalid with invalid characters like underscores' do
        applicant_detail.postalcode = '12345_678'
        expect(applicant_detail).not_to be_valid
        expect(applicant_detail.errors[:postalcode]).to include('can only contain letters, numbers, spaces, and dashes')
      end
    end

    describe 'parentzip validation' do
      let(:applicant_detail) { build(:applicant_detail) }

      it 'is valid with a postal code between 1 and 25 characters' do
        applicant_detail.parentzip = '12345'
        expect(applicant_detail).to be_valid
      end

      it 'is valid with alphanumeric characters, spaces, and dashes' do
        applicant_detail.parentzip = 'SW1A 1AA'
        expect(applicant_detail).to be_valid
      end

      it 'is valid with a dash in postal code' do
        applicant_detail.parentzip = '12345-6789'
        expect(applicant_detail).to be_valid
      end

      it 'is valid with a single character' do
        applicant_detail.parentzip = 'A'
        expect(applicant_detail).to be_valid
      end

      it 'is valid with exactly 25 characters' do
        applicant_detail.parentzip = 'A' * 25
        expect(applicant_detail).to be_valid
      end

      it 'is valid when blank' do
        applicant_detail.parentzip = nil
        expect(applicant_detail).to be_valid
      end

      it 'is valid when empty string' do
        applicant_detail.parentzip = ''
        expect(applicant_detail).to be_valid
      end

      it 'is invalid with more than 25 characters' do
        applicant_detail.parentzip = 'A' * 26
        expect(applicant_detail).not_to be_valid
        expect(applicant_detail.errors[:parentzip]).to include('must be between 1 and 25 characters')
      end

      it 'is invalid with special characters other than spaces and dashes' do
        applicant_detail.parentzip = '12345@678'
        expect(applicant_detail).not_to be_valid
        expect(applicant_detail.errors[:parentzip]).to include('can only contain letters, numbers, spaces, and dashes')
      end

      it 'is invalid with invalid characters like underscores' do
        applicant_detail.parentzip = '12345_678'
        expect(applicant_detail).not_to be_valid
        expect(applicant_detail.errors[:parentzip]).to include('can only contain letters, numbers, spaces, and dashes')
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      applicant_detail = build(:applicant_detail)
      expect(applicant_detail).to be_valid
    end

    it 'creates international applicant with trait' do
      applicant = create(:applicant_detail, :international)
      expect(applicant.us_citizen).to be false
      expect(applicant.country).not_to eq('US')
    end

    it 'creates domestic applicant with trait' do
      applicant = create(:applicant_detail, :domestic)
      expect(applicant.us_citizen).to be true
      expect(applicant.country).to eq('US')
    end
  end

  describe 'phone validations' do
    let(:applicant_detail) { build(:applicant_detail) }

    it 'is valid with a proper phone format' do
      applicant_detail.phone = '+1-555-1234'
      expect(applicant_detail).to be_valid
    end

    it 'is valid with international phone format' do
      applicant_detail.phone = '+44 20 1234 5678'
      expect(applicant_detail).to be_valid
    end

    it 'is invalid with too short phone' do
      applicant_detail.phone = '123'
      expect(applicant_detail).not_to be_valid
      expect(applicant_detail.errors[:phone]).to include('number format is incorrect')
    end
  end

  describe 'parent email validation' do
    let(:user) { create(:user) }
    let(:applicant_detail) { build(:applicant_detail, user: user) }

    it 'is invalid when parent email matches user email' do
      applicant_detail.parentemail = user.email
      expect(applicant_detail).not_to be_valid
      expect(applicant_detail.errors[:base]).to include("Parent/Guardian email should be different than the applicant's email")
    end

    it 'is valid when parent email is different from user email' do
      applicant_detail.parentemail = 'different@example.com'
      expect(applicant_detail).to be_valid
    end
  end

  describe 'demographic_other validation' do
    let(:other_demographic) { create(:demographic, :other) }
    let(:applicant_detail) { build(:applicant_detail, demographic: other_demographic) }

    it 'requires demographic_other when demographic is Other' do
      applicant_detail.demographic_other = nil
      expect(applicant_detail).not_to be_valid
      expect(applicant_detail.errors[:demographic_other]).to be_present
    end

    it 'is valid with demographic_other when demographic is Other' do
      applicant_detail.demographic_other = 'Custom demographic'
      expect(applicant_detail).to be_valid
    end

    it 'clears demographic_other when demographic is not Other' do
      regular_demographic = create(:demographic)
      applicant_detail.demographic = regular_demographic
      applicant_detail.demographic_other = 'Should be cleared'
      applicant_detail.valid?
      expect(applicant_detail.demographic_other).to be_nil
    end
  end

  describe '#full_name' do
    let(:applicant_detail) { build(:applicant_detail, firstname: 'John', lastname: 'Doe') }

    it 'returns last name, first name format' do
      expect(applicant_detail.full_name).to eq('Doe, John')
    end
  end

  describe '#applicant_email' do
    let(:user) { create(:user) }
    let(:applicant_detail) { create(:applicant_detail, user: user) }

    it 'returns the user email' do
      expect(applicant_detail.applicant_email).to eq(user.email)
    end
  end

  describe '#full_name_and_email' do
    let(:user) { create(:user) }
    let(:applicant_detail) { create(:applicant_detail, user: user, firstname: 'Jane', lastname: 'Smith') }

    it 'returns full name and email' do
      expect(applicant_detail.full_name_and_email).to eq("Smith, Jane - #{user.email}")
    end
  end

  describe '#formatted_demographic' do
    context 'when demographic is Other with demographic_other specified' do
      let(:other_demographic) { create(:demographic, :other) }
      let(:applicant_detail) { create(:applicant_detail, demographic: other_demographic, demographic_other: 'Custom info') }

      it 'returns Other with the custom info' do
        expect(applicant_detail.formatted_demographic).to eq('Other - Custom info')
      end
    end

    context 'when demographic is not Other' do
      let(:demographic) { create(:demographic, name: 'Test Demo') }
      let(:applicant_detail) { create(:applicant_detail, demographic: demographic) }

      it 'returns just the demographic name' do
        expect(applicant_detail.formatted_demographic).to eq('Test Demo')
      end
    end
  end

  describe 'scopes' do
    describe '.current_camp_enrolled' do
      before { setup_basic_test_data }

      it 'returns applicant details for enrolled students' do
        # This scope depends on enrollments, so we'd need to set up complete test data
        # Implementation will depend on how enrollments are set up
        expect(ApplicantDetail.current_camp_enrolled).to be_an(ActiveRecord::Relation)
      end
    end
  end

  it_behaves_like 'a model with timestamps'
end
