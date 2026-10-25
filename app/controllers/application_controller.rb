# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Responses carry QuickBooks customer data, and Intuit requires no-store on pages with sensitive data.
  before_action { response.cache_control.merge!(no_store: true) }

  rescue_from QuickbooksOauth::ReauthorizationRequired, with: :authorize_with_intuit

  def intuit_authenticate
    authorize_with_intuit
  end

  def acquire_token
    return if IntuitAccount.instance.access_token

    authorize_with_intuit
  end

  def intuit_callback
    return callback_failure("The authorization could not be verified. Start again.", :forbidden) unless state_matches?
    return callback_failure("QuickBooks access was not granted.", :unprocessable_content) if params[:error].present?
    return callback_failure("That is not the company this application is set up for.", :forbidden) unless realm_matches?

    account.save_token_from_code(params[:code], api_oauth_callback_url)
    target = session.delete(:target)
    target ? redirect_to(invoice_path(target)) : render(plain: "Connected to QuickBooks")
  rescue OAuth2::Error
    # An authorization code is single use and short lived, so a bad one means the user has to start over.
    callback_failure("QuickBooks rejected the authorization. Start again.", :bad_request)
  end

  def account
    IntuitAccount.instance
  end

  private

  # The state we issued with the grant URL must come back, or anyone could link their own company by sending a code.
  def state_matches?
    expected = session.delete(:oauth_state)
    expected.present? && ActiveSupport::SecurityUtils.secure_compare(expected, params[:state].to_s)
  end

  # The credentials name the one company this app reads; a grant for any other company must not replace its token.
  def realm_matches?
    ActiveSupport::SecurityUtils.secure_compare(IntuitAccount.realm.to_s, params[:realmId].to_s)
  end

  def callback_failure(message, status)
    render plain: message, status:
  end

  def authorize_with_intuit
    # A server-to-server caller can't follow Intuit's consent page, so tell it what is wrong instead.
    unless request.headers["Accept"].to_s.include?("text/html")
      return render plain: "QuickBooks authorization is needed. Contact IT.", status: :service_unavailable
    end

    session[:target] = params[:id]
    session[:oauth_state] = SecureRandom.hex(12)
    redirect_to account.grant_url(api_oauth_callback_url, state: session[:oauth_state]), allow_other_host: true
  end
end
