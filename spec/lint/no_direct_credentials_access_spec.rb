# frozen_string_literal: true

require "rails_helper"

# Enforced so the secret storage backend can change (e.g. AWS Secrets Manager) without touching call sites.
RSpec.describe "Direct Rails.credentials access" do # rubocop:disable RSpec/DescribeClass
  subject(:offenders) do
    `grep -rnE "Rails\\.(application\\.)?credentials" app config lib`.lines.map(&:chomp).reject do |match|
      path, _lineno, content = match.split(":", 3)
      path == "lib/application_secrets.rb" || content.strip.start_with?("#")
    end
  end

  it("is not used in app/, config/ or lib/ outside ApplicationSecrets") { expect(offenders).to be_empty }
end
