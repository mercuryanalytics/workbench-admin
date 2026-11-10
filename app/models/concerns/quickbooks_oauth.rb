# frozen_string_literal: true

module QuickbooksOauth
  extend ActiveSupport::Concern

  # Intuit no longer honours the stored grant (revoked by the user, or expired), so the user must authorize again.
  class ReauthorizationRequired < RuntimeError; end

  included do
    delegate :oauth_client, to: :class
  end

  def refresh_token!
    refresh_token = oauth_access_token.refresh!
    update_from(refresh_token)
  rescue OAuth2::Error => e
    raise ReauthorizationRequired, e.code if e.code == "invalid_grant"

    raise
  end

  def save_token_from_code(code, redirect_uri)
    resp = oauth_client.auth_code.get_token(code, redirect_uri:)
    update_from(resp) if resp
  end

  def update_from(oauth_token)
    access_token = oauth_token.token
    expires_at = Time.at(oauth_token.expires_at).utc
    refresh_token = oauth_token.refresh_token
    refresh_lifetime = [oauth_token.params["x_refresh_token_expires_in"].to_i.seconds, 100.days].max
    refresh_expires_at = Time.current + refresh_lifetime
    update!(access_token:, expires_at:, refresh_token:, refresh_expires_at:)
  end

  def grant_url(redirect_uri, state:)
    oauth_client.auth_code.authorize_url(
      redirect_uri:,
      response_type: "code",
      state:,
      scope: "com.intuit.quickbooks.accounting"
    )
  end

  def oauth_access_token
    OAuth2::AccessToken.new(oauth_client, access_token, refresh_token:)
  end

  module ClassMethods
    # Built per call, not memoized, so the endpoints follow the (cached) discovery document.
    def oauth_client
      OAuth2::Client.new(oauth_client_id, oauth_client_secret, oauth_options)
    end

    # Production credentials hold the live app; every other environment's hold the sandbox app and set intuit_app.
    def intuit_app
      ApplicationSecrets.intuit_app&.to_sym || :live
    end

    def realm
      ApplicationSecrets.intuit_realm_id
    end

    def oauth_client_id
      ApplicationSecrets.intuit_client_id
    end

    def oauth_client_secret
      ApplicationSecrets.intuit_client_secret
    end

    def oauth_options
      endpoints = IntuitDiscovery.endpoints(intuit_app)
      {
        site: endpoints["authorization_endpoint"],
        authorize_url: endpoints["authorization_endpoint"],
        token_url: endpoints["token_endpoint"]
      }
    end
  end
end
