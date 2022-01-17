# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def intuit_authenticate
    redirect_to account.grant_url(api_oauth_callback_url), allow_other_host: true
  end

  def intuit_callback
    # can use params[:state] to retrieve user information

    account.get_refresh_token(params[:code], api_oauth_callback_url)
    redirect_to experiments_path
  end

  def account
    IntuitAccount.instance
  end
end
