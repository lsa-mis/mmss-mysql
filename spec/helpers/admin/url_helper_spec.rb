# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::UrlHelper, type: :helper do
  def stub_query_parameters(params)
    allow(helper.request).to receive(:query_parameters).and_return(params)
  end

  describe "#admin_index_params" do
    it "keeps only known index params and always forces only_path" do
      stub_query_parameters(
        "q" => {"firstname_cont" => "Ada"},
        "scope" => "all",
        "sort" => "lastname",
        "direction" => "asc",
        "page" => "2",
        "limit" => "50"
      )

      expect(helper.admin_index_params).to eq(
        q: {"firstname_cont" => "Ada"},
        scope: "all",
        sort: "lastname",
        direction: "asc",
        page: "2",
        limit: "50",
        only_path: true
      )
    end

    it "drops host/protocol/port/script_name so index links cannot become off-site URLs" do
      stub_query_parameters(
        "host" => "evil.example",
        "protocol" => "https",
        "port" => "443",
        "script_name" => "/spoof",
        "sort" => "title",
        "page" => "3"
      )

      params = helper.admin_index_params

      expect(params).to eq(sort: "title", page: "3", only_path: true)
      expect(params.keys).not_to include(:host, :protocol, :port, :script_name)
    end

    it "converts a Parameters q filter to an unsafe hash for url_for" do
      stub_query_parameters(
        "q" => ActionController::Parameters.new("email_cont" => "camper@example.com"),
        "scope" => "pending"
      )

      expect(helper.admin_index_params[:q]).to eq("email_cont" => "camper@example.com")
      expect(helper.admin_index_params[:scope]).to eq("pending")
    end

    it "applies overrides and compact-removes nil keys (e.g. reset page on sort)" do
      stub_query_parameters("sort" => "old", "page" => "4", "scope" => "all")

      expect(helper.admin_index_params(sort: "title", page: nil)).to eq(
        sort: "title",
        scope: "all",
        only_path: true
      )
    end
  end

  describe "#admin_index_hidden_fields" do
    it "emits hidden inputs for carried-over scalar params" do
      stub_query_parameters("scope" => "waitlisted", "sort" => "lastname", "page" => "2")

      html = helper.admin_index_hidden_fields

      expect(html).to include('name="scope"', 'value="waitlisted"')
      expect(html).to include('name="sort"', 'value="lastname"')
      expect(html).to include('name="page"', 'value="2"')
      expect(html).not_to include("only_path")
    end

    it "emits nested hidden inputs for q filters and honours except:" do
      stub_query_parameters(
        "q" => {"firstname_cont" => "Ada"},
        "scope" => "all",
        "page" => "5"
      )

      html = helper.admin_index_hidden_fields(except: %i[page])

      expect(html).to include('name="q[firstname_cont]"', 'value="Ada"')
      expect(html).to include('name="scope"', 'value="all"')
      expect(html).not_to include('name="page"')
    end
  end
end
