# frozen_string_literal: true

# One account's segment and counts for one week (identified by the Monday that starts it). It is the only long-term
# record the report keeps; SegmentReport reads last week's row to find each account's segment change.
class AccountWeek < ApplicationRecord
  # Replaces any rows already recorded for the week, so a report can be rerun.
  def self.record(rows, week:)
    attributes = rows.map { |row| row.to_h.except(:previous_segment, :segment_change).merge(week:) }
    upsert_all(attributes, unique_by: %i[client_id week]) if attributes.any? # rubocop:disable Rails/SkipsModelValidations
  end
end
