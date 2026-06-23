require 'faker'

# Deterministic faker output keeps local/staging data stable across runs.
Faker::Config.random = Random.new(42)

year = Time.zone.now.year
date1 = Date.new(year, 6, 23)

Gender.find_or_create_by!(name: 'Male') { |g| g.description = 'Male' }
Gender.find_or_create_by!(name: 'Female') { |g| g.description = 'Female' }

# "Other" is protected in production migrations; match that so admin UI behaves like real data.
[
  { name: 'African American', description: 'African American', protected: false },
  { name: 'Asian American', description: 'Asian American', protected: false },
  { name: 'Hispanic American', description: 'Hispanic American', protected: false },
  { name: 'Native American', description: 'Native American', protected: false },
  { name: 'Pacific Islander', description: 'Pacific Islander', protected: false },
  { name: 'White', description: 'White', protected: false },
  { name: 'Other', description: 'Other demographic option', protected: true }
].each do |attrs|
  Demographic.find_or_create_by!(name: attrs[:name]) do |d|
    d.description = attrs[:description]
    d.protected = attrs[:protected]
  end
end

Admin.find_or_create_by!(email: 'admin@example.com') do |a|
  a.password = 'passwordpassword'
  a.password_confirmation = 'passwordpassword'
end

offer_letter = "<p>Please do not submit your admission response until you are
    certain of your ability to attend, as you will not have the option to
    change your answer electronically once submitted. </p> <p>Once you have
    accepted the invitation to MMSS, <strong>please upload the information
    packet and make your payment no later than the deadline listed below to
    finalize admission</strong>. Financial aid award decisions will be
    announced in April. If you applied for aid, you may disregard the payment
    deadline in this letter. You will be notified of your actual payment
    deadline in your financial aid award notice.</p> <p>Students who do not
    respond and submit all required materials by <strong>the deadline listed
    below</strong> will be placed on a waitlist for further admission if
    openings become available.</p> <p>We look forward to meeting you this
    summer, and again, congratulations on your admission! </p>"

waitlist_letter = "<p> As time progresses, if more spots become available, a
    second review of your file might be completed. If this happens and you are
    admitted from the waitlist, you will be notified via email. We do not have a
    waitlist ranking order, however, we will take into account the date in
    which your application was complete when placing students into open
    positions. It is typical for us to accept qualified candidates from the
    waitlist up until just two weeks before the session is to start. If you
    already know or decide in the future that you no longer wish to remain on
    the waitlist, please let us know. If we are unable to offer you a final
    letter of admission this summer, please note that each year we receive
    more than twice as many applications as we have spots available, and this
    limited space simply does not allow us to accept everyone. Thank you for
    your interest in our program, and we wish you the best of luck on your
    future endeavors. </p>"

camp_configuration = CampConfiguration.find_or_initialize_by(camp_year: year)
if camp_configuration.new_record?
  # CampConfiguration allows only one active row; clear others before activating this year.
  CampConfiguration.where(active: true).update_all(active: false)
  camp_configuration.assign_attributes(
    application_open: Date.new(year, 1, 16),
    application_close: Date.new(year, 6, 1),
    priority: Date.new(year, 5, 1),
    application_materials_due: Date.new(year, 6, 1),
    camper_acceptance_due: Date.new(year, 6, 1),
    application_fee_cents: 10_000,
    active: true,
    offer_letter: offer_letter,
    waitlist_letter: waitlist_letter,
    reject_letter: 'rejection message'
  )
  camp_configuration.save!
end

camp1 = camp_configuration.camp_occurrences.find_or_create_by!(description: 'Session 1') do |co|
  co.begin_date = date1
  co.end_date = date1 + 12.days
  co.cost_cents = 10_000
  co.active = true
end

camp2 = camp_configuration.camp_occurrences.find_or_create_by!(description: 'Session 2') do |co|
  co.begin_date = date1 + 14.days
  co.end_date = date1 + 26.days
  co.cost_cents = 10_000
  co.active = true
end

camp3 = camp_configuration.camp_occurrences.find_or_create_by!(description: 'Session 3') do |co|
  co.begin_date = date1 + 28.days
  co.end_date = date1 + 40.days
  co.cost_cents = 10_000
  co.active = true
end

camp_configuration.camp_occurrences.find_or_create_by!(description: 'Any Session') do |co|
  co.begin_date = date1
  co.end_date = date1 + 40.days
  co.cost_cents = 0
  co.active = true
end

camp1_courses = [
  { title: 'Survey in Modern Physics', available_spaces: 16, status: 'open', faculty_uniqname: 'smith' },
  { title: 'Greatest Hits in Vertebrate Evolution', available_spaces: 16, status: 'open', faculty_uniqname: 'einstein' },
  { title: 'Data, Distributions and Decisions: The Science of Statistics', available_spaces: 16, status: 'open',
    faculty_uniqname: 'bohr' },
  { title: 'Catalysis, Solar Energy and Green Chemical Synthesis', available_spaces: 16, status: 'open',
    faculty_uniqname: 'lawrence' },
  { title: 'Art and Mathematics', available_spaces: 16, status: 'open', faculty_uniqname: 'markum' },
  { title: 'The Physics of Magic and the Magic of Physics', available_spaces: 16, status: 'open',
    faculty_uniqname: 'teach' },
  { title: 'Life, Death and Change: Landscapes and Human Impact', available_spaces: 16, status: 'open',
    faculty_uniqname: 'bohr' },
  { title: 'Hex and the 4 Cs', available_spaces: 16, status: 'open', faculty_uniqname: 'bohr' },
  { title: 'Data Science of Happiness', available_spaces: 16, status: 'open', faculty_uniqname: 'lawrence' },
  { title: 'Climbing the Distance Ladder to the Big Bang: How Astronomers Survey the Universe', available_spaces: 16,
    status: 'open', faculty_uniqname: 'bohr' },
  { title: 'Sustainable Polymers', available_spaces: 25, status: 'open', faculty_uniqname: 'bohr' },
  { title: 'Surface Chemistry', available_spaces: 16, status: 'open', faculty_uniqname: 'smith' },
  { title: 'Relativity: A Journey through Warped Space and Time', available_spaces: 16, status: 'open',
    faculty_uniqname: 'bohr' },
  { title: 'Organic Chemistry 101: Orgo Boot Camp', available_spaces: 16, status: 'open', faculty_uniqname: 'einstein' }
]

camp2_courses = [
  { title: 'Mathematics of Cryptography', available_spaces: 16, status: 'open', faculty_uniqname: 'einstein' },
  { title: 'Human Identification: Forensic Anthropology Methods', available_spaces: 16, status: 'open',
    faculty_uniqname: 'smith' },
  { title: 'Fibonacci Numbers', available_spaces: 16, status: 'open', faculty_uniqname: 'teach' },
  { title: 'Dissecting Life: Human Anatomy and Physiology', available_spaces: 16, status: 'open',
    faculty_uniqname: 'bohr' },
  { title: 'Brain and Behavior', available_spaces: 16, status: 'open', faculty_uniqname: 'teach' },
  { title: 'Organic Chemistry 101: Orgo Boot Camp', available_spaces: 16, status: 'open', faculty_uniqname: 'einstein' },
  { title: 'Mathematics of Decisions, Elections and Games', available_spaces: 16, status: 'open',
    faculty_uniqname: 'bohr' },
  { title: 'Mathematics and the Internet', available_spaces: 16, status: 'open', faculty_uniqname: 'einstein' },
  { title: 'Graph Theory', available_spaces: 16, status: 'open', faculty_uniqname: 'smith' },
  { title: 'Forensic Physics', available_spaces: 16, status: 'open', faculty_uniqname: 'teach' },
  { title: 'Mathematics and Music Theory', available_spaces: 16, status: 'open', faculty_uniqname: 'markum' },
  { title: 'Mathematical Modeling in Biology', available_spaces: 16, status: 'open', faculty_uniqname: 'bohr' },
  { title: 'Catalysis, Solar Energy and Green Chemical Synthesis', available_spaces: 16, status: 'open',
    faculty_uniqname: 'lawrence' }
]

camp3_courses = [
  { title: 'Mathematics of Cryptography', available_spaces: 16, status: 'open', faculty_uniqname: 'einstein' },
  { title: 'Human Identification: Forensic Anthropology Methods', available_spaces: 16, status: 'open',
    faculty_uniqname: 'smith' },
  { title: 'Fibonacci Numbers', available_spaces: 16, status: 'open', faculty_uniqname: 'teach' },
  { title: 'Dissecting Life: Human Anatomy and Physiology', available_spaces: 16, status: 'open',
    faculty_uniqname: 'bohr' },
  { title: 'Brain and Behavior', available_spaces: 16, status: 'open', faculty_uniqname: 'teach' },
  { title: 'Art and Mathematics', available_spaces: 16, status: 'open', faculty_uniqname: 'markum' },
  { title: 'The Physics of Magic and the Magic of Physics', available_spaces: 16, status: 'open',
    faculty_uniqname: 'teach' },
  { title: 'Life, Death and Change: Landscapes and Human Impact', available_spaces: 16, status: 'open',
    faculty_uniqname: 'bohr' },
  { title: 'Hex and the 4 Cs', available_spaces: 16, status: 'open', faculty_uniqname: 'bohr' },
  { title: 'Data Science of Happiness', available_spaces: 16, status: 'open', faculty_uniqname: 'lawrence' },
  { title: 'Mathematics and Music Theory', available_spaces: 16, status: 'open', faculty_uniqname: 'markum' },
  { title: 'Mathematical Modeling in Biology', available_spaces: 16, status: 'open', faculty_uniqname: 'bohr' },
  { title: 'Forensic Physics', available_spaces: 16, status: 'open', faculty_uniqname: 'lawrence' },
  { title: 'Catalysis, Solar Energy and Green Chemical Synthesis', available_spaces: 16, status: 'open',
    faculty_uniqname: 'lawrence' }
]

[camp1, camp2, camp3].zip([camp1_courses, camp2_courses, camp3_courses]).each do |camp, courses|
  courses.each do |attrs|
    camp.courses.find_or_create_by!(title: attrs[:title]) do |course|
      course.available_spaces = attrs[:available_spaces]
      course.status = attrs[:status]
      course.faculty_uniqname = attrs[:faculty_uniqname]
    end
  end
end

%w[smith@umich.edu markum@umich.edu teach@umich.edu einstein@umich.edu bohr@umich.edu lawrence@umich.edu].each do |email|
  Faculty.find_or_create_by!(email: email) do |f|
    f.password = 'secretsecret'
    f.password_confirmation = 'secretsecret'
  end
end

def seed_activities_for(camp)
  [
    { description: 'Airport Shuttle - departure', date_occurs: camp.end_date, cost_cents: 2500, active: true },
    { description: 'Commuter Lunch', date_occurs: camp.begin_date, cost_cents: 11_500, active: true },
    { description: 'Late Departure', date_occurs: camp.end_date + 1.day, cost_cents: 10_000, active: true },
    { description: 'Early Arrival', date_occurs: camp.begin_date - 1.day, cost_cents: 10_000, active: true },
    { description: 'Sunday Trip', date_occurs: camp.begin_date + 7.days, cost_cents: 6000, active: true },
    { description: 'Airport Shuttle - roundtrip', date_occurs: camp.begin_date, cost_cents: 5000, active: true },
    { description: 'Dormitory (Residential Stay)', date_occurs: camp.begin_date, cost_cents: 100_000, active: true },
    { description: 'Cedar Point', date_occurs: camp.begin_date + 6.days, cost_cents: 8500, active: true },
    { description: 'Airport Shuttle - arrival', date_occurs: camp.end_date, cost_cents: 2500, active: true }
  ].each do |attrs|
    camp.activities.find_or_create_by!(description: attrs[:description]) do |activity|
      activity.date_occurs = attrs[:date_occurs]
      activity.cost_cents = attrs[:cost_cents]
      activity.active = attrs[:active]
    end
  end
end

seed_activities_for(camp1)
seed_activities_for(camp2)
seed_activities_for(camp3)

users = 8.times.map do
  User.find_or_create_by!(email: Faker::Internet.email) do |u|
    u.password = 'secretsecret'
    u.password_confirmation = 'secretsecret'
  end
end

# Must match values in app/views/applicant_details/_form.html.erb (not "x-large").
shirt_sizes = %w[small medium large xlarge 2xlarge No\ Shirt]

users.each do |u|
  demographic = Demographic.all.sample
  ApplicantDetail.find_or_create_by!(user_id: u.id) do |ad|
    ad.firstname = Faker::Name.first_name
    ad.lastname = Faker::Name.last_name
    ad.gender = Gender.all.sample.id.to_s
    ad.us_citizen = Faker::Boolean.boolean
    ad.birthdate = Faker::Date.birthday(min_age: 13, max_age: 18)
    ad.shirt_size = shirt_sizes.sample
    ad.address1 = Faker::Address.street_address
    ad.city = Faker::Address.city
    ad.state = Faker::Address.state
    ad.postalcode = Faker::Address.zip_code
    ad.country = Faker::Address.country
    ad.phone = '517-369-6986'
    ad.parentname = Faker::Name.name
    ad.parentphone = '397.693.1309'
    # Must differ from applicant email (ApplicantDetail#parentemail_not_user_email).
    ad.parentemail = "guardian#{u.id}@example.com"
    ad.demographic = demographic
    ad.demographic_other = demographic.name.casecmp('other').zero? ? 'Other Demographic Details' : nil
  end
end
