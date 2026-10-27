# frozen_string_literal: true

module Petasos
  class Project < Record
    belongs_to :client, foreign_key: :domain_id, inverse_of: :projects

    # { client_id => project_number } for each client's most recently updated project.
    def self.latest_numbers_by_client
      order(:updated_at).pluck(:domain_id, :project_number).to_h
    end
  end
end
