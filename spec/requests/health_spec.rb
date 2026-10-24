# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /up" do
  it "is healthy without touching QuickBooks" do
    get "/up"

    expect(response).to have_http_status(:ok)
  end
end
