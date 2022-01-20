# frozen_string_literal: true

class IntuitAccount < OauthToken
  class TooManyRetries < RuntimeError; end

  def self.instance
    @instance ||= first_or_initialize
  end

  def with_token
    retries = 3
    begin
      yield oauth_access_token
    rescue OAuth2::Error, Quickbooks::AuthorizationFailure
      retries -= 1
      raise TooManyRetries if retries <= 0

      refresh_token!
      retry
    end
  end
end
