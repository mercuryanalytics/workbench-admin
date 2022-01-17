# frozen_string_literal: true

Rails.application.config.intuit_realm = if Rails.env.production?
                                          raise "Need production realm id"
                                        else
                                          "4620816365181655620"
                                        end
Quickbooks.sandbox_mode = !Rails.env.production?
