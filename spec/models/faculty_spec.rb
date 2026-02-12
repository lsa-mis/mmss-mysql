# frozen_string_literal: true

# == Schema Information
#
# Table name: faculties
#
#  id                     :bigint           not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_faculties_on_email                 (email) UNIQUE
#  index_faculties_on_reset_password_token  (reset_password_token) UNIQUE
#
require 'rails_helper'

RSpec.describe Faculty, type: :model do
  describe 'validations' do
    let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let(:camp_occurrence) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let(:faculty_uniqname) { 'testfaculty' }
    
    before do
      create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname)
    end

    subject { build(:faculty, email: "#{faculty_uniqname}@university.edu") }

    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    
    it 'validates email presence through Devise' do
      faculty = build(:faculty, email: '', password: 'password123')
      faculty.valid?
      expect(faculty.errors[:email]).to be_present
    end
  end

  describe 'database columns' do
    it { is_expected.to have_db_column(:id).of_type(:integer) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:encrypted_password).of_type(:string) }
    it { is_expected.to have_db_column(:sign_in_count).of_type(:integer) }
    it { is_expected.to have_db_column(:current_sign_in_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:last_sign_in_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:current_sign_in_ip).of_type(:string) }
    it { is_expected.to have_db_column(:last_sign_in_ip).of_type(:string) }
  end

  describe 'database indexes' do
    it { is_expected.to have_db_index(:email).unique }
    it { is_expected.to have_db_index(:reset_password_token).unique }
  end

  describe 'Devise configuration' do
    it 'is database authenticatable' do
      expect(described_class.devise_modules).to include(:database_authenticatable)
    end

    it 'is registerable' do
      expect(described_class.devise_modules).to include(:registerable)
    end

    it 'is recoverable' do
      expect(described_class.devise_modules).to include(:recoverable)
    end

    it 'is rememberable' do
      expect(described_class.devise_modules).to include(:rememberable)
    end

    it 'is validatable' do
      expect(described_class.devise_modules).to include(:validatable)
    end
  end

  describe 'custom validation: faculty_has_courses' do
    let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let(:camp_occurrence) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let(:faculty_uniqname) { 'testfaculty' }
    let(:faculty_email) { "#{faculty_uniqname}@university.edu" }

    context 'when faculty has courses in current camp' do
      before do
        create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname)
      end

      it 'is valid' do
        faculty = build(:faculty, email: faculty_email)
        expect(faculty).to be_valid
      end
    end

    context 'when faculty does not have courses in current camp' do
      before do
        # Create a course with different faculty uniqname
        create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: 'otherfaculty')
      end

      it 'is invalid' do
        faculty = build(:faculty, email: faculty_email)
        expect(faculty).not_to be_valid
        expect(faculty.errors[:base]).to include("You don't have any courses, please contact the administrator")
      end
    end

    context 'when no active camp exists' do
      before do
        CampConfiguration.update_all(active: false)
      end

      it 'is invalid' do
        faculty = build(:faculty, email: faculty_email)
        expect(faculty).not_to be_valid
        expect(faculty.errors[:base]).to include("You don't have any courses, please contact the administrator")
      end
    end

    context 'when faculty has courses in inactive camp' do
      let(:inactive_camp_config) { create(:camp_configuration, active: false, camp_year: Date.current.year - 1) }
      let(:inactive_camp_occurrence) { create(:camp_occurrence, camp_configuration: inactive_camp_config, active: false) }

      before do
        create(:course, camp_occurrence: inactive_camp_occurrence, faculty_uniqname: faculty_uniqname)
      end

      it 'is invalid' do
        faculty = build(:faculty, email: faculty_email)
        expect(faculty).not_to be_valid
        expect(faculty.errors[:base]).to include("You don't have any courses, please contact the administrator")
      end
    end

    context 'when email has different domain format' do
      before do
        create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname)
      end

      it 'extracts uniqname correctly from email' do
        faculty = build(:faculty, email: "#{faculty_uniqname}@example.com")
        expect(faculty).to be_valid
      end
    end
  end

  describe 'factory' do
    let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let(:camp_occurrence) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let(:faculty_uniqname) { 'factoryfaculty' }

    before do
      create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname)
    end

    it 'has a valid factory' do
      faculty = build(:faculty, email: "#{faculty_uniqname}@university.edu")
      expect(faculty).to be_valid
    end

    it 'creates a faculty with valid email' do
      faculty = create(:faculty, email: "#{faculty_uniqname}@university.edu")
      expect(faculty.email).to be_present
      expect(faculty.email).to match(/\A[\w.]+@[\w.-]+\.\w+\z/)
    end

    it 'creates a faculty with encrypted password' do
      faculty = create(:faculty, email: "#{faculty_uniqname}@university.edu")
      expect(faculty.encrypted_password).to be_present
      expect(faculty.encrypted_password).not_to eq('FacultyPassword123!')
    end
  end

  describe 'sign in tracking' do
    let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let(:camp_occurrence) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let(:faculty_uniqname) { 'trackingfaculty' }
    let(:faculty) { create(:faculty, email: "#{faculty_uniqname}@university.edu") }

    before do
      create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname)
    end

    it 'has default sign_in_count of 0' do
      expect(faculty.sign_in_count).to eq(0)
    end

    it 'tracks sign in count' do
      faculty.update(sign_in_count: 5)
      expect(faculty.sign_in_count).to eq(5)
    end

    it 'tracks sign in timestamps' do
      time = Time.current
      faculty.update(
        current_sign_in_at: time,
        last_sign_in_at: time - 1.day
      )
      expect(faculty.current_sign_in_at).to be_within(1.second).of(time)
      expect(faculty.last_sign_in_at).to be_within(1.second).of(time - 1.day)
    end

    it 'tracks IP addresses' do
      faculty.update(
        current_sign_in_ip: '192.168.1.1',
        last_sign_in_ip: '192.168.1.2'
      )
      expect(faculty.current_sign_in_ip).to eq('192.168.1.1')
      expect(faculty.last_sign_in_ip).to eq('192.168.1.2')
    end
  end

  describe 'password reset' do
    let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let(:camp_occurrence) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let(:faculty_uniqname) { 'resetfaculty' }
    let(:faculty) { create(:faculty, email: "#{faculty_uniqname}@university.edu") }

    before do
      create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname)
    end

    it 'can generate reset password token' do
      faculty.send_reset_password_instructions
      expect(faculty.reset_password_token).to be_present
      expect(faculty.reset_password_sent_at).to be_present
    end
  end

  describe 'remember me' do
    let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let(:camp_occurrence) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let(:faculty_uniqname) { 'rememberfaculty' }
    let(:faculty) { create(:faculty, email: "#{faculty_uniqname}@university.edu") }

    before do
      create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname)
    end

    it 'can set remember created at' do
      faculty.update(remember_created_at: Time.current)
      expect(faculty.remember_created_at).to be_present
    end
  end
end
