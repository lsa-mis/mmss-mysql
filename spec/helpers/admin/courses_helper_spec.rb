# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::CoursesHelper, type: :helper do
  describe '#admin_course_status_options' do
    it 'returns the standard open/closed options for a blank status' do
      course = build_stubbed(:course, status: nil)

      expect(helper.admin_course_status_options(course)).to eq(helper.course_status)
    end

    it 'appends a persisted status that is not in course_status so the select cannot clear it' do
      course = build_stubbed(:course, status: 'waitlisted')

      options = helper.admin_course_status_options(course)

      expect(options).to include(%w[open open], %w[closed closed])
      expect(options).to include(%w[waitlisted waitlisted])
    end

    it 'does not duplicate a status that is already in course_status' do
      course = build_stubbed(:course, status: 'open')

      expect(helper.admin_course_status_options(course)).to eq(helper.course_status)
    end
  end
end
