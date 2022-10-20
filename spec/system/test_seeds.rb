Gender.create!([
  {name: "Female", description: "dudette"},
  {name: "Male", description: "dude"}
])

camp_configuration = CampConfiguration.create([
  {camp_year: 2022, application_open: "2022-01-01", application_close: "2022-11-01", priority: "2022-04-01", application_materials_due: "2022-05-20", camper_acceptance_due: "2022-06-01", application_fee_cents: 10000, active: true}
])

camp_config = CampConfiguration.first

camp_occurrence = camp_config.camp_occurrences.create([
  {description: "Session 1", begin_date: "2022-09-14", end_date: "2022-09-21", cost_cents: 20000, active: true},
  {description: "Session 2", begin_date: "2022-09-23", end_date: "2022-09-30", cost_cents: 20000, active: true},
  {description: "Session 3", begin_date: "2022-10-3", end_date: "2022-10-10", cost_cents: 20000, active: true}
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