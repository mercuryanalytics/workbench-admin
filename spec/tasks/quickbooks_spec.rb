# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "quickbooks:keep_alive" do
  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?("quickbooks:keep_alive")
    Rake::Task["quickbooks:keep_alive"].reenable
    allow(Rollbar).to receive(:error)
  end

  let!(:account) { create(:intuit_account) }

  it "reports a lapsed authorization to Rollbar and aborts" do
    error = QuickbooksOauth::ReauthorizationRequired.new("invalid_grant")
    allow(IntuitAccount.instance).to receive(:refresh_token!).and_raise(error)

    expect { Rake::Task["quickbooks:keep_alive"].invoke }.to raise_error(SystemExit)
    expect(Rollbar).to have_received(:error).with(error, /has lapsed/)
  end

  it "reports any other refresh failure to Rollbar and re-raises" do
    error = Faraday::ConnectionFailed.new("down")
    allow(IntuitAccount.instance).to receive(:refresh_token!).and_raise(error)

    expect { Rake::Task["quickbooks:keep_alive"].invoke }.to raise_error(error)
    expect(Rollbar).to have_received(:error).with(error, /failed/)
  end
end
