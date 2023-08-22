# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
users = User.create([
  {email: Faker::Internet.email, password: "secretsecret", password_confirmation: "secretsecret"},
  {email: Faker::Internet.email, password: "secretsecret", password_confirmation: "secretsecret"},
  {email: Faker::Internet.email, password: "secretsecret", password_confirmation: "secretsecret"},
  {email: Faker::Internet.email, password: "secretsecret", password_confirmation: "secretsecret"},
  {email: Faker::Internet.email, password: "secretsecret", password_confirmation: "secretsecret"},
  {email: Faker::Internet.email, password: "secretsecret", password_confirmation: "secretsecret"},
  {email: Faker::Internet.email, password: "secretsecret", password_confirmation: "secretsecret"},
  {email: Faker::Internet.email, password: "secretsecret", password_confirmation: "secretsecret"}
])

Gender.create!([
  {name: "Male", description: "dude type"},
  {name: "Female", description: "dudette type"}
])

Admin.create([
  {email: "rsmoke@umich.edu", password: "secretsecret", password_confirmation: "secretsecret"},
  {email: "admin@example.com", password: "passwordpassword", password_confirmation: "passwordpassword"}
])

CampConfiguration.create!(
  camp_year: Time.now.year,
  application_open: DateTime.now - 1,
  application_close: DateTime.now + 10,
  priority: DateTime.now + 3,
  application_materials_due: DateTime.now + 5,
  camper_acceptance_due: DateTime.now + 30,
  application_fee_cents: 10000,
  active: true,
  offer_letter: "offer",
  waitlist_letter: "wait",
  reject_letter: "reject"
)

camp_configuration = CampConfiguration.first

camp_configuration.camp_occurrences.create([
  {description: "Session 1", begin_date: "2023-07-14", end_date: "2023-07-21", cost_cents: 20000, active: true},
  {description: "Session 2", begin_date: "2023-08-23", end_date: "2023-08-30", cost_cents: 20000, active: true},
  {description: "Session 3", begin_date: "2023-10-3", end_date: "2023-10-10", cost_cents: 20000, active: true}
])

camp1 = CampOccurrence.active.first
camp2 = CampOccurrence.active.second

camp1.courses.create([
  {title: "Survey in Modern Physics", available_spaces: 16, status: "open"},
  {title: "Greatest Hits in Vertebrate Evolution", available_spaces: 16, status: "open"},
  {title: "Data, Distributions and Decisions: The Science of Statistics", available_spaces: 16, status: "open"},
  {title: "Catalysis, Solar Energy and Green Chemical Synthesis", available_spaces: 16, status: "open"},
  {title: "Art and Mathematics", available_spaces: 16, status: "open"},
  {title: "The Physics of Magic and the Magic of Physics", available_spaces: 16, status: "open"},
  {title: "Life, Death and Change: Landscapes and Human Impact", available_spaces: 16, status: "open"},
  {title: "Hex and the 4 Cs", available_spaces: 16, status: "open"},
  {title: "Data Science of Happiness", available_spaces: 16, status: "open"},
  {title: "Climbing the Distance Ladder to the Big Bang: How Astronomers Survey the Universe", available_spaces: 16, status: "open"},
  {title: "Sustainable Polymers", available_spaces: 25, status: "open"},
  {title: "Surface Chemistry", available_spaces: 16, status: "open"},
  {title: "Relativity: A Journey through Warped Space and Time", available_spaces: 16, status: "open"},
  {title: "Organic Chemistry 101: Orgo Boot Camp", available_spaces: 16, status: "open"}
])

camp2.courses.create([
  {title: "Mathematics of Cryptography", available_spaces: 16, status: "open"},
  {title: "Human Identification: Forensic Anthropology Methods", available_spaces: 16, status: "open"},
  {title: "Fibonacci Numbers", available_spaces: 16, status: "open"},
  {title: "Dissecting Life: Human Anatomy and Physiology", available_spaces: 16, status: "open"},
  {title: "Brain and Behavior", available_spaces: 16, status: "open"},
  {title: "Organic Chemistry 101: Orgo Boot Camp", available_spaces: 16, status: "open"},
  {title: "Mathematics of Decisions, Elections and Games", available_spaces: 16, status: "open"},
  {title: "Mathematics and the Internet", available_spaces: 16, status: "open"},
  {title: "Graph Theory", available_spaces: 16, status: "open"},
  {title: "Forensic Physics", available_spaces: 16, status: "open"},
  {title: "Mathematics and Music Theory", available_spaces: 16, status: "open"},
  {title: "Mathematical Modeling in Biology", available_spaces: 16, status: "open"},
  {title: "Forensic Physics", available_spaces: 16, status: "open"},
  {title: "Catalysis, Solar Energy and Green Chemical Synthesis", available_spaces: 16, status: "open"}
])

gender_type = ["Male", "Female"]

shirt_sizes = ["small", "medium", "large", "x-large"]

users.each do |u|
  ApplicantDetail.create!(
    user_id: u.id,
    firstname: Faker::Name.first_name,
    lastname: Faker::Name.last_name,
    gender: gender_type.sample,
    us_citizen: Faker::Boolean.boolean,
    birthdate: Faker::Date.birthday(min_age: 13, max_age: 18),
    shirt_size: shirt_sizes.sample,
    address1: Faker::Address.street_address,
    city: Faker::Address.city,
    state: Faker::Address.state,
    postalcode: Faker::Address.zip,
    country: Faker::Address.country,
    phone: Faker::PhoneNumber.cell_phone,
    parentname: Faker::Name.name,
    parentphone: Faker::PhoneNumber.cell_phone,
    parentemail: Faker::Internet.email
  )
end

users.each do |u|
  Enrollment.create!(
    user_id: u.id,
    international: Faker::Boolean.boolean,
    high_school_name: Faker::Educator.secondary_school,
    high_school_address1: Faker::Address.street_address,
    high_school_address2: Faker::Address.secondary_address,
    high_school_city: Faker::Address.city,
    high_school_state: Faker::Address.state,
    high_school_postalcode: Faker::Address.zip,
    high_school_country: Faker::Address.country,
    year_in_school: Faker::Number.between(from: 9, to: 12),
    anticipated_graduation_year: Faker::Number.between(from: 2021, to: 2025),
    room_mate_request: Faker::Name.name,
    personal_statement: Faker::Lorem.paragraph(sentence_count: 10),
    notes: Faker::Lorem.paragraph(sentence_count: 2),
    partner_program: Faker::Educator.university,
    campyear: Time.now.year,
    application_deadline: DateTime.now + 20,
    session_registration_ids: [camp1.id, camp2.id],
    course_registration_ids: [camp1.courses.first.id, camp2.courses.first.id],
    self.transcript.attach(io: File.open(Rails.root.join("app/assets/images/seed/MyHigh_Transcript.pdf")), filename: "transcript.pdf")
  )
end
