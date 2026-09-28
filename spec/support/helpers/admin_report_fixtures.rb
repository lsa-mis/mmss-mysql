# frozen_string_literal: true

# A small camp that gives every Admin::Reports report at least one row: complete applications
# (with recommendation, financial aid request, course preferences), a waitlisted application,
# an accepted offer with an awarded financial aid and a payment, enrolled students with accepted
# session assignments (one in two sessions), course assignments and activities including the
# dormitory, plus a registered user who never applied. One applicant's name starts with `=` so
# the CSV formula guard is exercised.
module AdminReportFixtures
  # CSV header row of every report (upper-cased, titleized SQL column aliases), taken from the
  # legacy ActiveAdmin downloads. `balance_due` used to be `balance_due_cents` renamed by the formatter.
  EXPECTED_HEADERS = {
    'all_complete_apps' => %w[LAST\ UPDATE NAME EMAIL GENDER US\ CITIZEN DEMOGRAPHIC BIRTHDATE DIET\ RESTRICTIONS
                              SHIRT\ SIZE ADDRESS PHONE PARENTNAME PARENT\ ADDRESS PARENTPHONE PARENTWORKPHONE
                              PARENTEMAIL USER INTERNATIONAL HIGH\ SCHOOL\ NAME HIGH\ SCHOOL\ ADDRESS YEAR\ IN\ SCHOOL
                              ANTICIPATED\ GRADUATION\ YEAR ROOM\ MATE\ REQUEST PERSONAL\ STATEMENT NOTES
                              APPLICATION\ STATUS OFFER\ STATUS RECOMMENDER\ EMAIL RECOMMENDER\ NAME
                              RECOMMENDER\ ORGANIZATION FIN\ AID\ AMOUNT FIN\ AID\ SOURCE FIN\ AID\ NOTE
                              FIN\ AID\ STATUS],
    'registered_but_not_applied' => %w[ID EMAIL NAME LAST\ USER\ LOGIN APPLICANT\ DETAILS\ CREATED],
    'pending_course_assignments_with_students' => %w[DESCRIPTION TITLE USER LASTNAME FIRSTNAME EMAIL],
    'accepted_course_assignments_with_students' => %w[DESCRIPTION TITLE USER LASTNAME FIRSTNAME EMAIL],
    'complete_applications_with_course_preferences' => %w[EMAIL LASTNAME FIRSTNAME RANKING TITLE DESCRIPTION],
    'waitlisted_applications_with_course_preferences' => %w[EMAIL LASTNAME FIRSTNAME RANKING TITLE DESCRIPTION],
    'finaid_with_app_and_offer_status' => %w[FIRSTNAME LASTNAME EMAIL APPLICATION\ STATUS OFFER\ STATUS],
    'complete_apps_demographic_report' => %w[COUNTRY GENDER YEAR\ IN\ SCHOOL DEMOGRAPHIC INTERNATIONAL],
    'offer_accepted_with_balance_due' => %w[NAME DATE\ OF\ BIRTH GENDER PARENT\ EMAIL BALANCE\ DUE],
    'enrolled_with_addresses' => %w[COUNTRY NAME LASTNAME FIRSTNAME EMAIL PARENTNAME PARENTPHONE PARENTEMAIL ADDRESS1
                                    ADDRESS2 CITY STATE STATE\ NON\ US POSTALCODE],
    'enrolled_student_demographic_report' => %w[COUNTRY GENDER YEAR\ IN\ SCHOOL DEMOGRAPHIC INTERNATIONAL],
    'enrolled_events_per_session' => %w[COUNTRY EVENT\ ACTIVITY SESSION LASTNAME FIRSTNAME EMAIL ROOM\ MATE\ REQUEST
                                        CITY STATE ID],
    'enrolled_with_sessions_and_courses' => %w[COUNTRY SESSION COURSE USER LASTNAME FIRSTNAME EMAIL YEAR\ IN\ SCHOOL
                                               STATE],
    'enrolled_with_sessions_and_tshirt' => %w[SESSION USER LASTNAME FIRSTNAME EMAIL SHIRT\ SIZE],
    'course_assignments' => %w[SESSION COURSE LASTNAME FIRSTNAME EMAIL COUNTRY STATE CITY GENDER AGE YEAR\ IN\ SCHOOL
                               PERSONAL\ STATEMENT],
    'enrolled_with_addresses_and_more' => %w[NAME LASTNAME FIRSTNAME EMAIL ADDRESS1 ADDRESS2 CITY STATE STATE\ NON\ US
                                             POSTALCODE COUNTRY BIRTHDATE GENDER DEMOGRAPHIC DEMOGRAPHIC\ OTHER
                                             GRADUATION\ YEAR YEAR\ IN\ SCHOOL],
    'enrolled_for_more_than_one_session' => %w[COUNTRY USER LASTNAME FIRSTNAME EMAIL SESSION COURSE YEAR\ IN\ SCHOOL
                                               STATE],
    'dorm_by_gender_by_session' => %w[COUNTRY EVENT\ ACTIVITY SESSION LASTNAME FIRSTNAME EMAIL GENDER
                                      ROOM\ MATE\ REQUEST CITY STATE]
  }.freeze

  ReportFixtures = Struct.new(:camp, :sessions, :courses, :dorm_activity, :complete, :formula, :waitlisted,
                              :accepted, :enrolled, :enrolled_two_sessions, :not_applied, keyword_init: true)

  def build_report_fixtures(camp_year: Date.current.year)
    CampConfiguration.where(active: true).update_all(active: false)
    camp = create(:camp_configuration, camp_year: camp_year, active: true, application_fee_cents: 10_000)
    sessions = [create(:camp_occurrence, camp_configuration: camp, description: 'Session A', cost_cents: 200_000),
                create(:camp_occurrence, camp_configuration: camp, description: 'Session B', cost_cents: 150_000)]
    courses = [create(:course, camp_occurrence: sessions[0], title: 'Number Theory'),
               create(:course, camp_occurrence: sessions[0], title: 'Topology'),
               create(:course, camp_occurrence: sessions[1], title: 'Statistics')]
    dorm = create(:activity, camp_occurrence: sessions[0], description: 'Dormitory (Residential Stay)',
                             cost_cents: 50_000)
    excursion = create(:activity, camp_occurrence: sessions[1], description: 'Cedar Point', cost_cents: 8_500)
    other = Demographic.find_or_create_by!(name: 'Other') do |d|
      d.description = 'Other'
      d.protected = true
    end
    female = Gender.find_or_create_by!(name: 'Female') { |g| g.description = 'Female' }

    complete = applicant(camp_year, :application_complete, firstname: 'Ada', lastname: 'Lovelace', gender: female.id,
                                                           demographic: other, demographic_other: 'Analytical engines')
    create(:recommendation, enrollment: complete, firstname: 'Charles', lastname: 'Babbage', organization: 'Cambridge')
    create(:financial_aid, enrollment: complete, amount_cents: 123_450, source: 'Scholarship', note: 'Needs aid',
                           status: 'pending')
    rank(complete, courses[0] => 1, courses[1] => 2)

    formula = applicant(camp_year, :application_complete, firstname: '=HYPERLINK("https://evil.example","x")',
                                                          lastname: 'Formula', country: 'CA', state: 'ON')
    rank(formula, courses[2] => 1)

    waitlisted = applicant(camp_year, :waitlisted, firstname: 'Grace', lastname: 'Hopper')
    rank(waitlisted, courses[0] => 1)

    accepted = applicant(camp_year, :accepted, firstname: 'Emmy', lastname: 'Noether', application_fee_required: true)
    create(:session_assignment, :accepted, enrollment: accepted, camp_occurrence: sessions[0])
    create(:course_assignment, enrollment: accepted, course: courses[0])
    create(:enrollment_activity, enrollment: accepted, activity: dorm)
    create(:financial_aid, enrollment: accepted, amount_cents: 100_000, status: 'awarded', note: 'Awarded')
    create(:payment, user: accepted.user, total_amount: '50000', transaction_status: '1', camp_year: camp_year)
    # Payment#set_status treats a first successful payment as the application fee and moves the
    # application to "submitted"; this one is a deposit on an accepted offer.
    accepted.update_columns(application_status: 'offer accepted')

    enrolled = applicant(camp_year, :enrolled, firstname: 'Mary', lastname: 'Cartwright', shirt_size: 'Medium',
                                               room_mate_request: 'Sofia Kovalevskaya')
    create(:session_assignment, :accepted, enrollment: enrolled, camp_occurrence: sessions[0])
    create(:course_assignment, enrollment: enrolled, course: courses[0])
    create(:enrollment_activity, enrollment: enrolled, activity: dorm)

    enrolled_two = applicant(camp_year, :enrolled, firstname: 'Sofia', lastname: 'Kovalevskaya', shirt_size: 'Large',
                                                   country: 'RU', state: 'Non-US', state_non_us: 'Moscow')
    sessions.each do |session|
      create(:session_assignment, :accepted, enrollment: enrolled_two, camp_occurrence: session)
    end
    create(:course_assignment, enrollment: enrolled_two, course: courses[1])
    create(:course_assignment, enrollment: enrolled_two, course: courses[2])
    create(:enrollment_activity, enrollment: enrolled_two, activity: excursion)

    not_applied = create(:user, :with_applicant_detail, email: 'lurker@example.com')

    ReportFixtures.new(camp: camp, sessions: sessions, courses: courses, dorm_activity: dorm, complete: complete,
                       formula: formula, waitlisted: waitlisted, accepted: accepted, enrolled: enrolled,
                       enrolled_two_sessions: enrolled_two, not_applied: not_applied)
  end

  private

  # The enrollment factory registers every course of the camp as a preference; rank the chosen ones.
  def rank(enrollment, rankings)
    rankings.each { |course, ranking| enrollment.course_preferences.find_by!(course: course).update!(ranking: ranking) }
  end

  def applicant(camp_year, status, firstname:, lastname:, **attributes)
    detail_keys = %i[gender demographic demographic_other country state state_non_us shirt_size]
    detail_attributes = attributes.extract!(*detail_keys)
    user = create(:user)
    create(:applicant_detail, user: user, firstname: firstname, lastname: lastname, **detail_attributes)
    create(:enrollment, status, user: user, campyear: camp_year, **attributes)
  end
end

RSpec.configure do |config|
  config.include AdminReportFixtures, type: :request
  config.include AdminReportFixtures, admin_reports: true
end
