# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
users = User.create([
  {email: 'chesttest@tester.com', password:'secretsecret', password_confirmation: 'secretsecret'},
  {email: "moe@tester.com", password: "secretsecret", password_confirmation: "secretsecret"},
  {email: 'bear@tester.com', password:'secretsecret', password_confirmation: 'secretsecret'},
  {email: "rick@tester.com", password: "secretsecret", password_confirmation: "secretsecret"},
  {email: 'tom@tester.com', password:'secretsecret', password_confirmation: 'secretsecret'},
  {email: "nick@tester.com", password: "secretsecret", password_confirmation: "secretsecret"},
  {email: 'homer@tester.com', password:'secretsecret', password_confirmation: 'secretsecret'},
  {email: "marge@tester.com", password: "secretsecret", password_confirmation: "secretsecret"}
  ])

applicant_detail = ApplicantDetail.create([
  {user_id: 3, firstname: "Lena", gender: "2", lastname: "Pet", us_citizen: true, birthdate: "2008-01-02", shirt_size: "medium", address1: "123 Main St", city: "Ann Arbor", state: "MI", postalcode: "48103", country: "US", phone: "555-123-4567", parentname: "My Mom", parentphone: "555-098-8765", parentemail: "parent@test.com"},
  {user_id: 4, firstname: "Ches", gender: "1", lastname: "Test", us_citizen: true, birthdate: "2008-01-02", shirt_size: "medium", address1: "123 Main St", city: "Ann Arbor", state: "MI", postalcode: "48103", country: "US", phone: "555-123-4567", parentname: "My Mom", parentphone: "555-098-8765", parentemail: "parent@test.com"},
  {user_id: 5, firstname: "Moe", gender: "1", lastname: "Person", us_citizen: true, birthdate: "2008-01-02", shirt_size: "medium", address1: "123 Main St", city: "Ann Arbor", state: "MI", postalcode: "48103", country: "US", phone: "555-123-4567", parentname: "My Mom", parentphone: "555-098-8765", parentemail: "parent@test.com"},
  {user_id: 6, firstname: "Bear", gender: "1", lastname: "Forest", us_citizen: true, birthdate: "2008-01-02", shirt_size: "medium", address1: "123 Main St", city: "Ann Arbor", state: "MI", postalcode: "48103", country: "US", phone: "555-123-4567", parentname: "My Mom", parentphone: "555-098-8765", parentemail: "parent@test.com"},
  {user_id: 7, firstname: "Rick", gender: "1", lastname: "Smoke", us_citizen: true, birthdate: "2008-01-02", shirt_size: "medium", address1: "123 Main St", city: "Ann Arbor", state: "MI", postalcode: "48103", country: "US", phone: "555-123-4567", parentname: "My Mom", parentphone: "555-098-8765", parentemail: "parent@test.com"},
  {user_id: 8, firstname: "Tom", gender: "1", lastname: "Smith", us_citizen: true, birthdate: "2008-01-02", shirt_size: "medium", address1: "123 Main St", city: "Ann Arbor", state: "MI", postalcode: "48103", country: "US", phone: "555-123-4567", parentname: "My Mom", parentphone: "555-098-8765", parentemail: "parent@test.com"},
  {user_id: 9, firstname: "Nick", gender: "1", lastname: "Barvinok", us_citizen: true, birthdate: "2008-01-02", shirt_size: "medium", address1: "123 Main St", city: "Ann Arbor", state: "MI", postalcode: "48103", country: "US", phone: "555-123-4567", parentname: "My Mom", parentphone: "555-098-8765", parentemail: "parent@test.com"},
  {user_id: 10, firstname: "Homer", gender: "1", lastname: "Simpson", us_citizen: true, birthdate: "2008-01-02", shirt_size: "medium", address1: "123 Main St", city: "Ann Arbor", state: "MI", postalcode: "48103", country: "US", phone: "555-123-4567", parentname: "My Mom", parentphone: "555-098-8765", parentemail: "parent@test.com"},
  {user_id: 11, firstname: "Marge", gender: "2", lastname: "Simpson", us_citizen: true, birthdate: "2008-01-02", shirt_size: "medium", address1: "123 Main St", city: "Ann Arbor", state: "MI", postalcode: "48103", country: "US", phone: "555-123-4567", parentname: "My Mom", parentphone: "555-098-8765", parentemail: "parent@test.com"}
])

admins = Admin.create([
  {email: 'rsmoke@umich.edu', password:'secretsecret', password_confirmation: 'secretsecret'}
  ])
  Admin.create!(email: 'admin@example.com', password: 'passwordpassword', password_confirmation: 'passwordpassword') if Rails.env.development?

gender = Gender.create([
  {name: "Female", description: "dudette"},
  {name: "Male", description: "dude"}
])

camp_configuration = CampConfiguration.create([
  {camp_year: 2021, application_open: "2021-01-01", application_close: "2021-05-01", priority: "2021-04-01", application_materials_due: "2021-05-20", camper_acceptance_due: "2021-06-01", application_fee_cents: 10000, active: true}
])

camp_config = CampConfiguration.first

camp_occurrence = camp_config.camp_occurrences.create([
  {description: "Session 1", begin_date: "2021-09-14", end_date: "2021-09-21", cost_cents: 20000, active: true},
  {description: "Session 2", begin_date: "2021-09-23", end_date: "2021-09-30", cost_cents: 20000, active: true},
  {description: "Session 3", begin_date: "2021-10-3", end_date: "2021-10-10", cost_cents: 20000, active: true}
  ])

  camp1 = CampOccurrence.first
  camp2 = CampOccurrence.second
  
  course1 = camp1.courses.create([
  {title: "Survey in Modern Physics",available_spaces: 16,status: "open"},
  {title: "Greatest Hits in Vertebrate Evolution",available_spaces: 16,status: "open"},
  {title: "Data, Distributions and Decisions: The Science of Statistics",available_spaces: 16,status: "open"},
  {title: "Catalysis, Solar Energy and Green Chemical Synthesis",available_spaces: 16,status: "open"},
  {title: "Art and Mathematics",available_spaces: 16,status: "open"},
  {title: "The Physics of Magic and the Magic of Physics",available_spaces: 16,status: "open"},
  {title: "Life, Death and Change: Landscapes and Human Impact",available_spaces: 16,status: "open"},
  {title: "Hex and the 4 Cs",available_spaces: 16,status: "open"},
  {title: "Data Science of Happiness",available_spaces: 16,status: "open"},
  {title: "Climbing the Distance Ladder to the Big Bang: How Astronomers Survey the Universe",available_spaces: 16,status: "open"},
  {title: "Sustainable Polymers",available_spaces: 25,status: "open"},
  {title: "Surface Chemistry",available_spaces: 16,status: "open"},
  {title: "Relativity: A Journey through Warped Space and Time",available_spaces: 16,status: "open"},
  {title: "Organic Chemistry 101: Orgo Boot Camp",available_spaces: 16,status: "open"}
  ])
  
  course2 = camp2.courses.create([
  {title: "Mathematics of Cryptography",available_spaces: 16,status: "open"},
  {title: "Human Identification: Forensic Anthropology Methods",available_spaces: 16,status: "open"},
  {title: "Fibonacci Numbers",available_spaces: 16,status: "open"},
  {title: "Dissecting Life: Human Anatomy and Physiology",available_spaces: 16,status: "open"},
  {title: "Brain and Behavior",available_spaces: 16,status: "open"},
  {title: "Organic Chemistry 101: Orgo Boot Camp",available_spaces: 16,status: "open"},
  {title: "Mathematics of Decisions, Elections and Games",available_spaces: 16,status: "open"},
  {title: "Mathematics and the Internet",available_spaces: 16,status: "open"},
  {title: "Graph Theory",available_spaces: 16,status: "open"},
  {title: "Forensic Physics",available_spaces: 16,status: "open"},
  {title: "Mathematics and Music Theory",available_spaces: 16,status: "open"},
  {title: "Mathematical Modeling in Biology",available_spaces: 16,status: "open"},
  {title: "Forensic Physics",available_spaces: 16,status: "open"},
  {title: "Catalysis, Solar Energy and Green Chemical Synthesis",available_spaces: 16,status: "open"}
  ])