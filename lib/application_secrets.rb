# frozen_string_literal: true

# Indirection layer over Rails.application.credentials. Every secret consumed by the app reads through here, so the
# storage layer can change (e.g. to AWS Secrets Manager) without touching call sites. Nested groups use `dig`, so a
# group that isn't configured yet reads as nil instead of failing the boot.
module ApplicationSecrets
  module_function

  # The production credentials hold the live Intuit app; every other environment's hold the sandbox app.
  def intuit_app = credentials.intuit_app
  def intuit_client_id = credentials.dig(:intuit, :client_id)
  def intuit_client_secret = credentials.dig(:intuit, :client_secret)
  def intuit_realm_id = credentials.dig(:intuit, :realm_id)

  # Read-only connection URLs for the petasos and thoth databases.
  def petasos_database_url = credentials.dig(:databases, :petasos)
  def thoth_database_url = credentials.dig(:databases, :thoth)

  # The same SES block petasos uses.
  def smtp_host = credentials.dig(:smtp, :host)
  def smtp_port = credentials.dig(:smtp, :port)
  def smtp_username = credentials.dig(:smtp, :username)
  def smtp_password = credentials.dig(:smtp, :password)
  def smtp_from = credentials.dig(:smtp, :from)

  def credentials = Rails.application.credentials
  private_class_method :credentials
end
