# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/oauth_callback", type: :request do
  let(:invalid_grant) do
    faraday = Faraday::Response.new(status: 400, body: { error: "invalid_grant" }.to_json,
                                    response_headers: { "Content-Type" => "application/json" })
    OAuth2::Error.new(OAuth2::Response.new(faraday))
  end
  let(:realmId) { IntuitAccount.realm } # rubocop:disable RSpec/VariableName -- Intuit's parameter name
  let(:state) { Rack::Utils.parse_query(URI(response.location).query)["state"] }

  before do
    allow(IntuitAccount.instance).to receive(:save_token_from_code)
  end

  def begin_authorization(path = invoice_path("Project 1"))
    get path
    state
  end

  it "stores the token and returns to the requested invoice", :aggregate_failures do
    get api_oauth_callback_path, params: { code: "abc", state: begin_authorization, realmId: }

    expect(IntuitAccount.instance).to have_received(:save_token_from_code).with("abc", api_oauth_callback_url)
    expect(response).to redirect_to(invoice_path("Project 1"))
  end

  it "refuses a callback whose state does not match", :aggregate_failures do
    begin_authorization
    get api_oauth_callback_path, params: { code: "abc", state: "forged" }

    expect(response).to have_http_status(:forbidden)
    expect(IntuitAccount.instance).not_to have_received(:save_token_from_code)
  end

  it "refuses a grant for a different company", :aggregate_failures do
    get api_oauth_callback_path, params: { code: "abc", state: begin_authorization, realmId: "999" }

    expect(response).to have_http_status(:forbidden)
    expect(IntuitAccount.instance).not_to have_received(:save_token_from_code)
  end

  it "refuses a grant that names no company", :aggregate_failures do
    get api_oauth_callback_path, params: { code: "abc", state: begin_authorization }

    expect(response).to have_http_status(:forbidden)
    expect(IntuitAccount.instance).not_to have_received(:save_token_from_code)
  end

  it "reports when the user does not grant access", :aggregate_failures do
    get api_oauth_callback_path, params: { error: "access_denied", state: begin_authorization, realmId: }

    expect(response).to have_http_status(:unprocessable_content)
    expect(IntuitAccount.instance).not_to have_received(:save_token_from_code)
  end

  it "asks the user to start again when Intuit rejects the code", :aggregate_failures do
    allow(IntuitAccount.instance).to receive(:save_token_from_code).and_raise(invalid_grant)

    get api_oauth_callback_path, params: { code: "stale", state: begin_authorization, realmId: }

    expect(response).to have_http_status(:bad_request)
    expect(response.body).to include("Start again")
  end

  it "refuses a callback that was never started", :aggregate_failures do
    get api_oauth_callback_path, params: { code: "abc", state: "anything" }

    expect(response).to have_http_status(:forbidden)
    expect(IntuitAccount.instance).not_to have_received(:save_token_from_code)
  end

  it "accepts a state only once", :aggregate_failures do
    valid = begin_authorization
    get api_oauth_callback_path, params: { code: "abc", state: valid, realmId: }
    get api_oauth_callback_path, params: { code: "abc", state: valid, realmId: }

    expect(response).to have_http_status(:forbidden)
  end
end
