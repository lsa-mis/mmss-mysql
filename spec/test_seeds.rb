# frozen_string_literal: true

Gender.find_or_create_by(name: 'Female') { |g| g.description = 'dudette' }
Gender.find_or_create_by(name: 'Male') { |g| g.description = 'dude' }

Demographic.find_or_create_by(name: 'Test Demographic') { |d| d.description = 'Test Description'; d.protected = false }
Demographic.find_or_create_by(name: 'Other') { |d| d.description = 'Other demographic option'; d.protected = true }

camp_config = CampConfiguration.find_or_create_by(camp_year: 2025) do |cc|
  cc.application_open = Date.current - 30.days
  cc.application_close = Date.current + 90.days
  cc.priority = Date.current + 30.days
  cc.application_materials_due = Date.current + 60.days
  cc.camper_acceptance_due = Date.current + 75.days
  cc.application_fee_cents = 10_000
  cc.active = true
  cc.offer_letter = 'Default offer letter'
  cc.reject_letter = 'Default reject letter'
  cc.waitlist_letter = 'Default waitlist letter'
end

camp_config.camp_occurrences.find_or_create_by(description: 'Session 1') do |co|
  co.begin_date = Date.current + 120.days
  co.end_date = Date.current + 127.days
  co.cost_cents = 20_000
  co.active = true
end

camp_config.camp_occurrences.find_or_create_by(description: 'Session 2') do |co|
  co.begin_date = Date.current + 130.days
  co.end_date = Date.current + 137.days
  co.cost_cents = 20_000
  co.active = true
end

camp_config.camp_occurrences.find_or_create_by(description: 'Session 3') do |co|
  co.begin_date = Date.current + 140.days
  co.end_date = Date.current + 147.days
  co.cost_cents = 20_000
  co.active = true
end

camp1 = CampOccurrence.first
camp2 = CampOccurrence.second

camp1.courses.find_or_create_by(title: 'Survey in Modern Physics') { |c| c.available_spaces = 16; c.status = 'open' }
camp1.courses.find_or_create_by(title: 'Greatest Hits in Vertebrate Evolution') { |c| c.available_spaces = 16; c.status = 'open' }
camp1.courses.find_or_create_by(title: 'Data, Distributions and Decisions: The Science of Statistics') { |c| c.available_spaces = 16; c.status = 'open' }
camp1.courses.find_or_create_by(title: 'Catalysis, Solar Energy and Green Chemical Synthesis') { |c| c.available_spaces = 16; c.status = 'open' }
camp1.courses.find_or_create_by(title: 'Art and Mathematics') { |c| c.available_spaces = 16; c.status = 'open' }
camp1.courses.find_or_create_by(title: 'The Physics of Magic and the Magic of Physics') { |c| c.available_spaces = 16; c.status = 'open' }
camp1.courses.find_or_create_by(title: 'Life, Death and Change: Landscapes and Human Impact') { |c| c.available_spaces = 16; c.status = 'open' }
camp1.courses.find_or_create_by(title: 'Hex and the 4 Cs') { |c| c.available_spaces = 16; c.status = 'open' }
camp1.courses.find_or_create_by(title: 'Data Science of Happiness') { |c| c.available_spaces = 16; c.status = 'open' }
camp1.courses.find_or_create_by(title: 'Climbing the Distance Ladder to the Big Bang: How Astronomers Survey the Universe') { |c| c.available_spaces = 16; c.status = 'open' }
camp1.courses.find_or_create_by(title: 'Sustainable Polymers') { |c| c.available_spaces = 25; c.status = 'open' }
camp1.courses.find_or_create_by(title: 'Surface Chemistry') { |c| c.available_spaces = 16; c.status = 'open' }
camp1.courses.find_or_create_by(title: 'Relativity: A Journey through Warped Space and Time') { |c| c.available_spaces = 16; c.status = 'open' }
camp1.courses.find_or_create_by(title: 'Organic Chemistry 101: Orgo Boot Camp') { |c| c.available_spaces = 16; c.status = 'open' }

camp2.courses.find_or_create_by(title: 'Mathematics of Cryptography') { |c| c.available_spaces = 16; c.status = 'open' }
camp2.courses.find_or_create_by(title: 'Human Identification: Forensic Anthropology Methods') { |c| c.available_spaces = 16; c.status = 'open' }
camp2.courses.find_or_create_by(title: 'Fibonacci Numbers') { |c| c.available_spaces = 16; c.status = 'open' }
camp2.courses.find_or_create_by(title: 'Dissecting Life: Human Anatomy and Physiology') { |c| c.available_spaces = 16; c.status = 'open' }
camp2.courses.find_or_create_by(title: 'Brain and Behavior') { |c| c.available_spaces = 16; c.status = 'open' }
camp2.courses.find_or_create_by(title: 'Organic Chemistry 101: Orgo Boot Camp') { |c| c.available_spaces = 16; c.status = 'open' }
camp2.courses.find_or_create_by(title: 'Mathematics of Decisions, Elections and Games') { |c| c.available_spaces = 16; c.status = 'open' }
camp2.courses.find_or_create_by(title: 'Mathematics and the Internet') { |c| c.available_spaces = 16; c.status = 'open' }
camp2.courses.find_or_create_by(title: 'Graph Theory') { |c| c.available_spaces = 16; c.status = 'open' }
camp2.courses.find_or_create_by(title: 'Forensic Physics') { |c| c.available_spaces = 16; c.status = 'open' }
camp2.courses.find_or_create_by(title: 'Mathematics and Music Theory') { |c| c.available_spaces = 16; c.status = 'open' }
camp2.courses.find_or_create_by(title: 'Mathematical Modeling in Biology') { |c| c.available_spaces = 16; c.status = 'open' }
camp2.courses.find_or_create_by(title: 'Forensic Physics') { |c| c.available_spaces = 16; c.status = 'open' }
camp2.courses.find_or_create_by(title: 'Catalysis, Solar Energy and Green Chemical Synthesis') { |c| c.available_spaces = 16; c.status = 'open' }
