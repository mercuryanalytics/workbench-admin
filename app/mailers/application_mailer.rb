# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { ApplicationSecrets.smtp_from }
  layout "mailer"
end
