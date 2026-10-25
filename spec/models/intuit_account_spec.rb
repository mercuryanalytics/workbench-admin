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
