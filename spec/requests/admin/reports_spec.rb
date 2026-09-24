# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin reports', type: :request do
  describe 'authentication' do
    it 'redirects anonymous visitors to the admin login page' do
      get admin_reports_path
      expect(response).to redirect_to(new_admin_session_path)

      get admin_report_path('all_complete_apps')
      expect(response).to redirect_to(new_admin_session_path)
    end

    it 'does not accept a signed-in applicant (User)' do
      sign_in create(:user)

      get admin_report_path('all_complete_apps')

      expect(response).to redirect_to(new_admin_session_path)
      expect(response.media_type).not_to eq('text/csv')
    end
  end

  context 'as an admin' do
    let!(:fixtures) { build_report_fixtures }
    let(:camp) { fixtures.camp }

    before { sign_in create(:admin) }

    describe 'GET /admin/reports' do
      it 'lists every report with its description, parameters and a download link for the active camp' do
        get admin_reports_path

        expect(response).to have_http_status(:ok)
        body = CGI.unescapeHTML(response.body)
        expect(body).to include("#{camp.camp_year} camp · 18 CSV reports")
        expect(body).to include('Applications', 'Enrolled students')

        Admin::Reports.all.each do |report|
          expect(body).to include(%(id="report_#{report.key}"))
          expect(body).to include(report.label)
          expect(body).to include(report.description)
          expect(body).to include(admin_report_path(report.key, camp_year: camp.camp_year))
        end
        expect(body).to include("Camp year = #{camp.camp_year}")
        expect(body.scan('Download CSV').size).to eq(18)
        expect(body).not_to include('legacy_admin/reports')
      end

      it 'offers every configured camp year and binds the downloads to the selected one' do
        older = create(:camp_configuration, camp_year: camp.camp_year - 1)

        get admin_reports_path(camp_year: older.camp_year)

        expect(response).to have_http_status(:ok)
        body = response.body
        expect(body).to include(%(<option selected="selected" value="#{older.camp_year}">#{older.camp_year}</option>))
        expect(body).to include(%(<option value="#{camp.camp_year}">#{camp.camp_year}</option>))
        expect(body).to include(admin_report_path('course_assignments', camp_year: older.camp_year))
        expect(body).not_to include(admin_report_path('course_assignments', camp_year: camp.camp_year))
      end

      it 'renders without an active camp and disables the downloads' do
        CampConfiguration.update_all(active: false)

        get admin_reports_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('No active camp')
        expect(response.body).not_to include(admin_report_path('all_complete_apps', camp_year: camp.camp_year))
        expect(response.body.scan('aria-disabled="true"').size).to eq(18)
      end

      it 'rejects an unknown camp year' do
        get admin_reports_path(camp_year: 1999)

        expect(response).to redirect_to(admin_reports_path)
        follow_redirect!
        expect(response.body).to include('Unknown report or camp year.')
      end

      it 'is linked from the sidebar as a ported page' do
        get admin_root_path

        expect(response.body).to include(%(href="#{admin_reports_path}"))
        expect(response.body).not_to include('legacy_admin/reports')
      end
    end

    describe 'GET /admin/reports/:id' do
      Admin::Reports.all.each do |report_class|
        it "downloads #{report_class.key} with the legacy title, count and header rows and at least one data row" do
          get admin_report_path(report_class.key)

          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq('text/csv')
          expect(response.headers['Content-Disposition'])
            .to match(/attachment; filename="MMSS-report-#{report_class.csv_title}-[A-Z][a-z]{2}-\d{1,2}-\d{4}\.csv"/)

          csv = CSV.parse(response.body)
          expect(csv[0]).to eq([report_class.csv_title.titleize])
          expect(csv[1]).to eq(["Total number of records: #{csv.size - 3}"])
          expect(csv[2]).to eq(AdminReportFixtures::EXPECTED_HEADERS.fetch(report_class.key))
          expect(csv.size).to be >= 4
        end
      end

      it 'lists complete applications with money-formatted financial aid' do
        get admin_report_path('all_complete_apps')

        csv = CSV.parse(response.body)
        name = csv[2].index('NAME')
        amount = csv[2].index('FIN AID AMOUNT')
        rows = csv.drop(3)
        expect(rows.map { |row| row[name] }).to include('Ada Lovelace')
        expect(rows.find { |row| row[name] == 'Ada Lovelace' }[amount]).to eq('$1,234.50')
        expect(rows.map { |row| row[name] }).not_to include('Grace Hopper', 'Mary Cartwright')
      end

      it 'computes the balance due in dollars' do
        get admin_report_path('offer_accepted_with_balance_due')

        csv = CSV.parse(response.body)
        expect(csv[3]).to eq(['Emmy Noether', fixtures.accepted.applicant_detail.birthdate.iso8601, 'Female',
                              fixtures.accepted.applicant_detail.parentemail, '$1,100.00'])
      end

      it 'lists registered users who never applied for the camp year' do
        get admin_report_path('registered_but_not_applied')

        csv = CSV.parse(response.body)
        expect(csv.drop(3).map { |row| row[1] }).to eq(['lurker@example.com'])
      end

      it 'renders country names and blanked class-list repeats' do
        get admin_report_path('dorm_by_gender_by_session')
        expect(CSV.parse(response.body)[3].first(5))
          .to eq(['United States of America - US', 'Dormitory (Residential Stay)', 'Session A', 'Cartwright', 'Mary'])

        get admin_report_path('course_assignments')
        expect(CSV.parse(response.body).drop(3).map { |row| row.first(2) })
          .to eq([['Session A', 'Number Theory'], ['', 'Topology'], ['Session B', 'Statistics']])
      end

      it 'lists only students enrolled in more than one session' do
        get admin_report_path('enrolled_for_more_than_one_session')

        rows = CSV.parse(response.body).drop(3)
        expect(rows.map { |row| row[2] }.uniq).to eq(['Kovalevskaya'])
        expect(rows.map { |row| row[5] }).to eq(['Session A', 'Session B'])
      end

      it 'downloads the selected camp year instead of the active one' do
        older = create(:camp_configuration, camp_year: camp.camp_year - 1)
        veteran = create(:user)
        create(:applicant_detail, user: veteran, firstname: 'Hypatia', lastname: 'Alexandria')
        create(:enrollment, :enrolled, user: veteran, campyear: older.camp_year)

        get admin_report_path('enrolled_with_addresses_and_more', camp_year: older.camp_year)

        csv = CSV.parse(response.body)
        expect(csv[1]).to eq(['Total number of records: 1'])
        expect(csv[3].first).to eq('Hypatia Alexandria')

        get admin_report_path('enrolled_with_addresses_and_more', camp_year: camp.camp_year)
        expect(CSV.parse(response.body).drop(3).map(&:first))
          .to contain_exactly('Mary Cartwright', 'Sofia Kovalevskaya')
      end

      it 'neutralises formula-leading cells' do
        get admin_report_path('complete_applications_with_course_preferences')

        firstnames = CSV.parse(response.body).drop(3).map { |row| row[2] }
        expect(firstnames).to include(%q('=HYPERLINK("https://evil.example","x")))
        expect(firstnames).not_to include('=HYPERLINK("https://evil.example","x")')
        expect(firstnames).to include('Ada')
      end

      it 'rejects an unknown report' do
        get admin_report_path('nonexistent_report')

        expect(response).to redirect_to(admin_reports_path)
        expect(response.media_type).not_to eq('text/csv')
        follow_redirect!
        expect(response.body).to include('Unknown report or camp year.')
      end

      it 'rejects a report key carrying a SQL fragment' do
        # Fails the route constraint (/[a-z_]+/), so it never reaches the controller.
        get '/admin/reports/all_complete_apps;DROP'

        expect(response).not_to have_http_status(:ok)
        expect(response.media_type).not_to eq('text/csv')

        get admin_report_path('all_complete_apps'), params: { id: 'users; DROP TABLE users' }

        expect(response).to have_http_status(:ok)
        expect(CSV.parse(response.body)[0]).to eq(['All Complete Applications'])
        expect(User.count).to be_positive
      end

      it 'rejects camp years that are not a configured four-digit year' do
        tampered = ['2026 OR 1=1', "#{camp.camp_year}; DROP TABLE users", '1999', '20260', 'abcd',
                    "#{camp.camp_year}.0", ' ', " #{camp.camp_year}", "#{camp.camp_year}\n"]
        tampered.each do |value|
          get admin_report_path('all_complete_apps', camp_year: value)

          expect(response).to redirect_to(admin_reports_path), "camp_year=#{value.inspect} was accepted"
          expect(response.media_type).not_to eq('text/csv')
        end

        [[camp.camp_year], [''], { year: camp.camp_year }].each do |value|
          get admin_report_path('all_complete_apps'), params: { camp_year: value }

          expect(response).to redirect_to(admin_reports_path), "camp_year=#{value.inspect} was accepted"
        end
      end

      it 'treats an absent or empty camp_year as the active camp' do
        get admin_report_path('all_complete_apps', camp_year: '')

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq('text/csv')
        expect(CSV.parse(response.body)[1]).to eq(['Total number of records: 2'])
      end

      it 'refuses to run without a camp' do
        CampConfiguration.update_all(active: false)

        get admin_report_path('all_complete_apps')

        expect(response).to redirect_to(admin_reports_path)
      end
    end
  end
end
