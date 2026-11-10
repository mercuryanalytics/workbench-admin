# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationSecrets do
  let(:credentials) { ActiveSupport::OrderedOptions.new }

  before { allow(Rails.application).to receive(:credentials).and_return(credentials) }

  it "#intuit_app reads credentials.intuit_app" do
    credentials[:intuit_app] = "sandbox"
    expect(described_class.intuit_app).to eq("sandbox")
  end

  {
    intuit_client_id: %i[intuit client_id],
    intuit_client_secret: %i[intuit client_secret],
    intuit_realm_id: %i[intuit realm_id],
    petasos_database_url: %i[databases petasos],
    thoth_database_url: %i[databases thoth],
    smtp_host: %i[smtp host],
    smtp_port: %i[smtp port],
    smtp_username: %i[smtp username],
    smtp_password: %i[smtp password],
    smtp_from: %i[smtp from]
  }.each do |method, (group, key)|
    it "##{method} reads credentials.#{group}.#{key}" do
      credentials[group] = { key => "value-#{method}" }
      expect(described_class.public_send(method)).to eq("value-#{method}")
    end

    it "##{method} is nil when the #{group} group isn't configured" do
      expect(described_class.public_send(method)).to be_nil
    end
  end

  it "does not expose the underlying credentials object publicly" do
    expect { described_class.credentials }.to raise_error(NoMethodError)
  end
end
