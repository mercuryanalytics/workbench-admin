# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/oauth_callback", type: :request do
  let(:state) { Rack::Utils.parse_query(URI(response.location).query)["state"] }

  before do
    allow(IntuitAccount.instance).to receive(:save_token_from_code)
  end

  def begin_authorization(path = invoice_path("Project 1"))
    get path
    state
  end

  it "stores the token and returns to the requested invoice", :aggregate_failures do
    get api_oauth_callback_path, params: { code: "abc", state: begin_authorization }

    expect(IntuitAccount.instance).to have_received(:save_token_from_code).with("abc", api_oauth_callback_url)
    expect(response).to redirect_to(invoice_path("Project 1"))
  end

  it "refuses a callback whose state does not match", :aggregate_failures do
    begin_authorization
    get api_oauth_callback_path, params: { code: "abc", state: "forged" }

    expect(response).to have_http_status(:forbidden)
    expect(IntuitAccount.instance).not_to have_received(:save_token_from_code)
  end

  it "refuses a callback that was never started", :aggregate_failures do
    get api_oauth_callback_path, params: { code: "abc", state: "anything" }

    expect(response).to have_http_status(:forbidden)
    expect(IntuitAccount.instance).not_to have_received(:save_token_from_code)
  end

  it "accepts a state only once", :aggregate_failures do
    valid = begin_authorization
    get api_oauth_callback_path, params: { code: "abc", state: valid }
    get api_oauth_callback_path, params: { code: "abc", state: valid }

    expect(response).to have_http_status(:forbidden)
  end
end
