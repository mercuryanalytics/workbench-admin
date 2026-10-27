# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Integration pages", type: :request do
  describe "GET /integration/connect" do
    before { allow(IntuitAccount.instance).to receive(:save_token_from_code) }

    it "sends a browser to Intuit with a state to verify", :aggregate_failures do
      get integration_connect_path

      expect(response).to have_http_status(:found)
      expect(response.location).to start_with("https://appcenter.intuit.com/connect/oauth2")
      expect(Rack::Utils.parse_query(URI(response.location).query)["state"]).to be_present
    end

    it "lets the callback finish the connection", :aggregate_failures do
      get integration_connect_path
      state = Rack::Utils.parse_query(URI(response.location).query)["state"]
      get api_oauth_callback_path, params: { code: "abc", state:, realmId: IntuitAccount.realm }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq "Connected to QuickBooks"
    end

    it "answers a caller that is not a browser with 503", :aggregate_failures do
      get integration_connect_path, headers: { "Accept" => "text/plain" }

      expect(response).to have_http_status(:service_unavailable)
    end
  end

  it "tells a user who disconnected QuickBooks to contact IT", :aggregate_failures do
    get integration_disconnected_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Contact IT to reconnect")
  end
end
