# frozen_string_literal: true

require "rails_helper"

RSpec.describe Petasos::Membership do
  describe ".user_rows" do
    subject { described_class.user_rows }

    let!(:membership) { create(:petasos_membership, user:) }
    let(:user) { create(:petasos_user, email: "Ann@Example.com", last_login: 2.days.ago) }

    it { is_expected.to eq [[membership.client_id, "ann@example.com", user.last_login]] }
  end
end
