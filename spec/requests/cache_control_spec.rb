# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cache-Control" do
  it "forbids caching of application responses" do
    get "/integration/qb-tos"

    expect(response.headers["Cache-Control"]).to eq "no-store"
  end
end
