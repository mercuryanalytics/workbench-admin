# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationConfig do
  let(:data) { ActiveSupport::OrderedOptions.new }

  around do |example|
    described_class.instance_variable_set(:@data, nil)
    example.run
  ensure
    described_class.instance_variable_set(:@data, nil)
  end

  before { allow(Rails.application).to receive(:config_for).with(:application_config).and_return(data) }

  it "#report_recipients reads data.report_recipients" do
    data.report_recipients = ["scottb@example.com"]
    expect(described_class.report_recipients).to eq(["scottb@example.com"])
  end

  it "#report_weeks_retained reads data.report_weeks_retained" do
    data.report_weeks_retained = 14
    expect(described_class.report_weeks_retained).to eq(14)
  end

  it "does not expose the underlying data object publicly" do
    expect { described_class.data }.to raise_error(NoMethodError)
  end
end
