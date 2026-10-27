# frozen_string_literal: true

require "rails_helper"

RSpec.describe IntuitDiscovery do
  let(:live_url) { described_class::DOCUMENTS.fetch(:live) }
  let(:published) do
    { "authorization_endpoint" => "https://auth.example/new", "token_endpoint" => "https://token.example/new", "jwks_uri" => "x" }
  end

  it "uses the endpoints in the discovery document", :aggregate_failures do
    stub_request(:get, live_url).to_return(body: published.to_json)

    endpoints = described_class.endpoints(:live)

    expect(endpoints["authorization_endpoint"]).to eq "https://auth.example/new"
    expect(endpoints["token_endpoint"]).to eq "https://token.example/new"
  end

  it "reads the sandbox document for the sandbox app" do
    stub_request(:get, described_class::DOCUMENTS.fetch(:sandbox)).to_return(body: published.to_json)

    expect(described_class.endpoints(:sandbox)["token_endpoint"]).to eq "https://token.example/new"
  end

  it "fetches a document only once within the refresh window" do
    stub_request(:get, live_url).to_return(body: published.to_json)

    2.times { described_class.endpoints(:live) }

    expect(a_request(:get, live_url)).to have_been_made.once
  end

  it "fetches again once the refresh window has passed" do
    stub_request(:get, live_url).to_return(body: published.to_json)
    described_class.endpoints(:live)

    travel_to(described_class::REFRESH_AFTER.from_now + 1.minute) { described_class.endpoints(:live) }

    expect(a_request(:get, live_url)).to have_been_made.twice
  end

  [
    ["the request fails", ->(stub) { stub.to_timeout }],
    ["the server errors", ->(stub) { stub.to_return(status: 500) }],
    ["the body is not JSON", ->(stub) { stub.to_return(body: "<html>") }]
  ].each do |reason, respond|
    it "falls back to the last known endpoints when #{reason}" do
      respond.call(stub_request(:get, live_url))

      expect(described_class.endpoints(:live)).to eq described_class::FALLBACK
    end
  end
end
