# frozen_string_literal: true

namespace :quickbooks do
  desc "Refresh the Intuit tokens so an idle app does not let the refresh token lapse"
  task keep_alive: :environment do
    account = IntuitAccount.instance
    abort "No QuickBooks authorization to keep alive" unless account.persisted?

    account.refresh_token!
    puts "QuickBooks token refreshed"
  rescue QuickbooksOauth::ReauthorizationRequired
    abort "QuickBooks authorization has lapsed; it must be reconnected"
  end
end
