# frozen_string_literal: true

# Indirection layer over per-environment configuration values that are not secrets. Backed by
# config/application_config.yml so the values live in source control alongside the code that consumes them.
module ApplicationConfig
  module_function

  # Who the weekly segment report is mailed to.
  def report_recipients = data.report_recipients

  def data = @data ||= Rails.application.config_for(:application_config)
  private_class_method :data
end
