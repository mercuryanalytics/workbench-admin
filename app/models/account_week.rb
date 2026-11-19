# frozen_string_literal: true

# One account's segment and counts for one week (identified by the Monday that starts it). It is the only long-term
# record the report keeps. SegmentReport reads last week's row to find each account's segment change, and the older
# weeks (see ApplicationConfig.report_weeks_retained) let the quarterly target be measured.
class AccountWeek < ApplicationRecord
  class AlreadyRecorded < StandardError; end

  # petasos overwrites last_login on every login, so a rerun after the week has passed sees fewer logins than the
  # original run did. Replacing the stored week has to be asked for.
  def self.record(rows, week:, force: false)
    raise AlreadyRecorded, "#{week} is already recorded; pass force to replace it" if !force && exists?(week:)

    attributes = rows.map { |row| row.to_h.except(:previous_segment, :segment_change).merge(week:) }
    upsert_all(attributes, unique_by: %i[client_id week]) if attributes.any? # rubocop:disable Rails/SkipsModelValidations
  end

  # Drops weeks older than `keep` weeks before the recorded one, so rerunning an old week can't clear newer history.
  def self.prune(week:, keep:)
    where(week: ...(week - keep.weeks)).delete_all
  end
end
