# frozen_string_literal: true

module Petasos
  class Membership < Record
    belongs_to :client
    belongs_to :user

    # One [client_id, email, last_login] row per account member. Email is the key shared with thoth.
    def self.user_rows
      email = Arel::Nodes::NamedFunction.new("lower", [User.arel_table[:email]])
      joins(:user).pluck(:client_id, email, User.arel_table[:last_login])
    end
  end
end
