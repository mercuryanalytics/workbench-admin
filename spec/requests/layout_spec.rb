# frozen_string_literal: true

require "rails_helper"

# Needs the esbuild and sass output: run `yarn build && yarn build:css` first.
RSpec.describe "Layout assets", type: :request do
  it "links the built stylesheet and script", :aggregate_failures do
    get integration_qb_tos_path

    expect(response.body).to match(%r{href="/assets/application-\h+\.css"})
    expect(response.body).to match(%r{src="/assets/application-\h+\.js"})
  end
end
