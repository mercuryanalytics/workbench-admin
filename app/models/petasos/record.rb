# frozen_string_literal: true

module Petasos
  class Record < ApplicationRecord
    self.abstract_class = true

    connects_to database: { writing: :petasos, reading: :petasos }
  end
end
