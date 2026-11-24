# frozen_string_literal: true

module Petasos
  class User < Record
    has_many :memberships, dependent: nil
  end
end
