# frozen_string_literal: true

# Indirection layer over per-environment configuration values that are not secrets. Backed by
# config/application_config.yml so the values live in source control alongside the code that consumes them.
module ApplicationConfig
  module_function

  # Who the weekly segment report is mailed to.
  def report_recipients = data.report_recipients

  # How many weeks of account_weeks to keep, a quarter plus the week it's compared with.
  def report_weeks_retained = data.report_weeks_retained

  def data = @data ||= Rails.application.config_for(:application_config)
  private_class_method :data
end
