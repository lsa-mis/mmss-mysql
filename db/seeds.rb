require 'faker'

users = User.create([
                      { email: Faker::Internet.email, password: 'secretsecret', password_confirmation: 'secretsecret' },
                      { email: Faker::Internet.email, password: 'secretsecret', password_confirmation: 'secretsecret' },
                      { email: Faker::Internet.email, password: 'secretsecret', password_confirmation: 'secretsecret' },
                      { email: Faker::Internet.email, password: 'secretsecret', password_confirmation: 'secretsecret' },
                      { email: Faker::Internet.email, password: 'secretsecret', password_confirmation: 'secretsecret' },
                      { email: Faker::Internet.email, password: 'secretsecret', password_confirmation: 'secretsecret' },
                      { email: Faker::Internet.email, password: 'secretsecret', password_confirmation: 'secretsecret' },
                      { email: Faker::Internet.email, password: 'secretsecret', password_confirmation: 'secretsecret' }
                    ])

Gender.create!([
                 { name: 'Male', description: 'dude type' },
                 { name: 'Female', description: 'dudette type' }
               ])

Demographic.create!([
                      { name: 'African American', description: 'African American' },
                      { name: 'Asian American', description: 'Asian American' },
                      { name: 'Hispanic American', description: 'Hispanic American' },
                      { name: 'Native American', description: 'Native American' },
                      { name: 'Pacific Islander', description: 'Pacific Islander' },
                      { name: 'White', description: 'White' },
                      { name: 'Other', description: 'Other' }
                    ])

Admin.create([
               { email: 'admin@example.com', password: 'passwordpassword', password_confirmation: 'passwordpassword' }
             ])

CampConfiguration.create!(
  camp_year: Time.now.year,
  application_open: DateTime.new(Time.now.year, 1, 16),
  application_close: DateTime.new(Time.now.year, 6, 1),
  priority: DateTime.new(Time.now.year, 5, 1),
  application_materials_due: DateTime.new(Time.now.year, 6, 1),
  camper_acceptance_due: DateTime.new(Time.now.year, 6, 1),
  application_fee_cents: 10_000,
  active: true,
  offer_letter: "<p>Please do not submit your admission response until you are
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
    summer, and again, congratulations on your admission! </p>",
  waitlist_letter: "<p> As time progresses, if more spots become available, a
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
    future endeavors. </p>",
  reject_letter: 'rejection message'
)

camp_configuration = CampConfiguration.first
date1 = DateTime.new(Time.now.year, 6, 23)

camp_configuration.camp_occurrences.create!([
                                              { description: 'Session 1', begin_date: date1, end_date: date1 + 12.days,
                                                cost_cents: 10_000, active: true },
                                              { description: 'Session 2', begin_date: date1 + 14.days, end_date: date1 + 26.days, cost_cents: 10_000,
                                                active: true },
                                              { description: 'Session 3', begin_date: date1 + 28.days, end_date: date1 + 40.days, cost_cents: 10_000,
                                                active: true },
                                              { description: 'Any Session', begin_date: date1,
                                                end_date: date1 + 40.days, cost_cents: 0, active: true }
                                            ])

camp1 = CampOccurrence.find_by(description: 'Session 1', active: true)
camp2 = CampOccurrence.find_by(description: 'Session 2', active: true)
camp3 = CampOccurrence.find_by(description: 'Session 3', active: true)

camp1.courses.create!([
                        { title: 'Survey in Modern Physics', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'smith' },
                        { title: 'Greatest Hits in Vertebrate Evolution', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'einstein' },
                        { title: 'Data, Distributions and Decisions: The Science of Statistics', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'bohr' },
                        { title: 'Catalysis, Solar Energy and Green Chemical Synthesis', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'lawrence' },
                        { title: 'Art and Mathematics', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'markum' },
                        { title: 'The Physics of Magic and the Magic of Physics', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'teach' },
                        { title: 'Life, Death and Change: Landscapes and Human Impact', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'bohr' },
                        { title: 'Hex and the 4 Cs', available_spaces: 16, status: 'open', faculty_uniqname: 'bohr' },
                        { title: 'Data Science of Happiness', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'lawrence' },
                        { title: 'Climbing the Distance Ladder to the Big Bang: How Astronomers Survey the Universe', available_spaces: 16,
                          status: 'open', faculty_uniqname: 'bohr' },
                        { title: 'Sustainable Polymers', available_spaces: 25, status: 'open',
                          faculty_uniqname: 'bohr' },
                        { title: 'Surface Chemistry', available_spaces: 16, status: 'open', faculty_uniqname: 'smith' },
                        { title: 'Relativity: A Journey through Warped Space and Time', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'bohr' },
                        { title: 'Organic Chemistry 101: Orgo Boot Camp', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'einstein' }
                      ])

camp2.courses.create!([
                        { title: 'Mathematics of Cryptography', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'einstein' },
                        { title: 'Human Identification: Forensic Anthropology Methods', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'smith' },
                        { title: 'Fibonacci Numbers', available_spaces: 16, status: 'open', faculty_uniqname: 'teach' },
                        { title: 'Dissecting Life: Human Anatomy and Physiology', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'bohr' },
                        { title: 'Brain and Behavior', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'teach' },
                        { title: 'Organic Chemistry 101: Orgo Boot Camp', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'einstein' },
                        { title: 'Mathematics of Decisions, Elections and Games', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'bohr' },
                        { title: 'Mathematics and the Internet', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'einstein' },
                        { title: 'Graph Theory', available_spaces: 16, status: 'open', faculty_uniqname: 'smith' },
                        { title: 'Forensic Physics', available_spaces: 16, status: 'open', faculty_uniqname: 'teach' },
                        { title: 'Mathematics and Music Theory', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'markum' },
                        { title: 'Mathematical Modeling in Biology', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'bohr' },
                        { title: 'Catalysis, Solar Energy and Green Chemical Synthesis', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'lawrence' }
                      ])

camp3.courses.create!([
                        { title: 'Mathematics of Cryptography', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'einstein' },
                        { title: 'Human Identification: Forensic Anthropology Methods', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'smith' },
                        { title: 'Fibonacci Numbers', available_spaces: 16, status: 'open', faculty_uniqname: 'teach' },
                        { title: 'Dissecting Life: Human Anatomy and Physiology', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'bohr' },
                        { title: 'Brain and Behavior', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'teach' },
                        { title: 'Art and Mathematics', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'markum' },
                        { title: 'The Physics of Magic and the Magic of Physics', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'teach' },
                        { title: 'Life, Death and Change: Landscapes and Human Impact', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'bohr' },
                        { title: 'Hex and the 4 Cs', available_spaces: 16, status: 'open', faculty_uniqname: 'bohr' },
                        { title: 'Data Science of Happiness', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'lawrence' },
                        { title: 'Mathematics and Music Theory', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'markum' },
                        { title: 'Mathematical Modeling in Biology', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'bohr' },
                        { title: 'Forensic Physics', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'lawrence' },
                        { title: 'Catalysis, Solar Energy and Green Chemical Synthesis', available_spaces: 16, status: 'open',
                          faculty_uniqname: 'lawrence' }
                      ])

Faculty.create!([
                  { email: 'smith@umich.edu', password: 'secretsecret', password_confirmation: 'secretsecret' },
                  { email: 'markum@umich.edu', password: 'secretsecret', password_confirmation: 'secretsecret' },
                  { email: 'teach@umich.edu', password: 'secretsecret', password_confirmation: 'secretsecret' },
                  { email: 'einstein@umich.edu', password: 'secretsecret', password_confirmation: 'secretsecret' },
                  { email: 'bohr@umich.edu', password: 'secretsecret', password_confirmation: 'secretsecret' },
                  { email: 'lawrence@umich.edu', password: 'secretsecret', password_confirmation: 'secretsecret' }
                ])

camp1.activities.create!([
                           { description: 'Airport Shuttle - departure', date_occurs: camp1.end_date, cost_cents: 2500,
                             active: true },
                           { description: 'Communter Lunch', date_occurs: camp1.begin_date, cost_cents: 11_500,
                             active: true },
                           { description: 'Late Departure', date_occurs: camp1.end_date + 1.day, cost_cents: 10_000,
                             active: true },
                           { description: 'Early Arrival', date_occurs: camp1.begin_date - 1.day, cost_cents: 10_000,
                             active: true },
                           { description: 'Sunday Trip', date_occurs: camp1.begin_date + 7.day, cost_cents: 6000,
                             active: true },
                           { description: 'Airport Shuttle - roundtrip', date_occurs: camp1.begin_date,
                             cost_cents: 5000, active: true },
                           { description: 'Dormitory (Residential Stay)', date_occurs: camp1.begin_date,
                             cost_cents: 100_000, active: true },
                           { description: 'Cedar Point', date_occurs: camp1.begin_date + 6.day, cost_cents: 8500,
                             active: true },
                           { description: 'Airport Shuttle - arrival', date_occurs: camp1.end_date, cost_cents: 2500,
                             active: true }
                         ])

camp2.activities.create!([
                           { description: 'Airport Shuttle - departure', date_occurs: camp2.end_date, cost_cents: 2500,
                             active: true },
                           { description: 'Communter Lunch', date_occurs: camp2.begin_date, cost_cents: 11_500,
                             active: true },
                           { description: 'Late Departure', date_occurs: camp2.end_date + 1.day, cost_cents: 10_000,
                             active: true },
                           { description: 'Early Arrival', date_occurs: camp2.begin_date - 1.day, cost_cents: 10_000,
                             active: true },
                           { description: 'Sunday Trip', date_occurs: camp2.begin_date + 7.day, cost_cents: 6000,
                             active: true },
                           { description: 'Airport Shuttle - roundtrip', date_occurs: camp2.begin_date,
                             cost_cents: 5000, active: true },
                           { description: 'Dormitory (Residential Stay)', date_occurs: camp2.begin_date,
                             cost_cents: 100_000, active: true },
                           { description: 'Cedar Point', date_occurs: camp2.begin_date + 6.day, cost_cents: 8500,
                             active: true },
                           { description: 'Airport Shuttle - arrival', date_occurs: camp2.end_date, cost_cents: 2500,
                             active: true }
                         ])

camp3.activities.create!([
                           { description: 'Airport Shuttle - departure', date_occurs: camp3.end_date, cost_cents: 2500,
                             active: true },
                           { description: 'Communter Lunch', date_occurs: camp3.begin_date, cost_cents: 11_500,
                             active: true },
                           { description: 'Late Departure', date_occurs: camp3.end_date + 1.day, cost_cents: 10_000,
                             active: true },
                           { description: 'Early Arrival', date_occurs: camp3.begin_date - 1.day, cost_cents: 10_000,
                             active: true },
                           { description: 'Sunday Trip', date_occurs: camp3.begin_date + 7.day, cost_cents: 6000,
                             active: true },
                           { description: 'Airport Shuttle - roundtrip', date_occurs: camp3.begin_date,
                             cost_cents: 5000, active: true },
                           { description: 'Dormitory (Residential Stay)', date_occurs: camp3.begin_date,
                             cost_cents: 100_000, active: true },
                           { description: 'Cedar Point', date_occurs: camp3.begin_date + 6.day, cost_cents: 8500,
                             active: true },
                           { description: 'Airport Shuttle - arrival', date_occurs: camp3.end_date, cost_cents: 2500,
                             active: true }
                         ])

shirt_sizes = %w[small medium large x-large]

users.each do |u|
  demographic = Demographic.all.sample
  ApplicantDetail.create!(
    user_id: u.id,
    firstname: Faker::Name.first_name,
    lastname: Faker::Name.last_name,
    gender: Gender.all.sample.id,
    us_citizen: Faker::Boolean.boolean,
    birthdate: Faker::Date.birthday(min_age: 13, max_age: 18),
    shirt_size: shirt_sizes.sample,
    address1: Faker::Address.street_address,
    city: Faker::Address.city,
    state: Faker::Address.state,
    postalcode: Faker::Address.zip,
    country: Faker::Address.country,
    phone: '517-369-6986',
    parentname: Faker::Name.name,
    parentphone: '397.693.1309',
    parentemail: Faker::Internet.email,
    demographic: demographic,
    demographic_other: demographic.name.downcase == 'other' ? 'Other Demographic Details' : nil
  )
end
