# frozen_string_literal: true

class IntegrationController < ApplicationController
  # The connect/reconnect URL registered with Intuit: starts the same state-protected grant a lookup does.
  def connect
    authorize_with_intuit
  end
end
