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
end
