# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "recommendations:issue_missing_upload_tokens" do
  before(:all) do
    Rake.application = Rake::Application.new
    Rake.application.rake_require("tasks/recommendations", [Rails.root.join("lib").to_s])
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task["recommendations:issue_missing_upload_tokens"] }

  it "issues tokens only to pending recommendations without one and sends nothing" do
    missing = create(:recommendation, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)))
    missing.update_columns(upload_token: nil, upload_token_expires_at: nil)
    active = create(:recommendation, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)))
    active_token = active.upload_token
    received = create(:recommendation, :with_upload, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)))

    expect {
      task.reenable
      task.invoke
    }.to output(/Issued upload tokens to 1 recommendation\./).to_stdout

    expect(missing.reload.upload_token).to be_present
    expect(missing).to be_upload_link_active
    expect(active.reload.upload_token).to eq(active_token)
    expect(received.reload.upload_token).to be_nil
    expect(ActionMailer::Base.deliveries).to be_empty
  end
end
