# frozen_string_literal: true

module Petasos
  class Client < Record
    has_many :memberships, dependent: nil
    has_many :users, through: :memberships
    has_many :projects, foreign_key: :domain_id, inverse_of: :client, dependent: nil
  end
end
