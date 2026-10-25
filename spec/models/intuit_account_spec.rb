# frozen_string_literal: true

require "rails_helper"

RSpec.describe IntuitAccount, type: :model do
  subject { create(:intuit_account) }

  it "has a valid factory" do
    expect(build(:intuit_account)).to be_valid
  end

  it "requires the instance to be unique" do
    create(:intuit_account)
    expect(build(:intuit_account)).not_to be_valid
  end

  it "can lookup keys by the issuer" do
    subject
    expect(described_class.instance).to eq subject
  end

  describe "#with_token" do
    let(:grant_error) do
      faraday = Faraday::Response.new(status: 400, body: { error: "invalid_grant" }.to_json,
                                      response_headers: { "Content-Type" => "application/json" })
      OAuth2::Error.new(OAuth2::Response.new(faraday))
    end

    it "asks for reauthorization when Intuit rejects the refresh token" do
      stored = instance_double(OAuth2::AccessToken)
      allow(OAuth2::AccessToken).to receive(:new).and_return(stored)
      allow(stored).to receive(:refresh!).and_raise(grant_error)

      expect { subject.with_token { raise Quickbooks::AuthorizationFailure } }
        .to raise_error(QuickbooksOauth::ReauthorizationRequired)
    end
  end

  describe "token storage" do
    let(:stored) do
      described_class.connection.select_one(
        "SELECT access_token, refresh_token FROM oauth_tokens WHERE id = #{subject.id}"
      )
    end

    it "does not store the tokens in plaintext" do
      expect(stored.values).not_to include(subject.access_token, subject.refresh_token)
    end

    it "decrypts the tokens when loading" do
      expect(described_class.find(subject.id).refresh_token).to eq subject.refresh_token
    end
  end
end
