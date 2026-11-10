# frozen_string_literal: true

module Thoth
  class Record < ApplicationRecord
    self.abstract_class = true

    connects_to database: { writing: :thoth, reading: :thoth }
  end
end
