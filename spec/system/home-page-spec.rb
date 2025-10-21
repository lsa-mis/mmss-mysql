# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home Page', type: :system do

  describe 'home page' do
    it 'shows the right content' do
      visit root_path
      expect(page).to have_content('Michigan Math and Science Scholars Registration')
      sleep(inspection_time=1)
    end
  end

end