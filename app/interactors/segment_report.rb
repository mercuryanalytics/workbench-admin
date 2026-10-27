# frozen_string_literal: true

# One row per petasos client, built from its members' activity in the period. Users are matched to thoth by email.
class SegmentReport
  include Interactor

  # Least to most engaged; a segment change is a move along this order.
  SEGMENTS = %i[dormant active activated power].freeze

  Row = Data.define(:client_id, :account, :users, :logins, :mercury_ai_reports, :ask_reports, :last_project, :segment,
                    :previous_segment, :segment_change)

  def self.csv(rows)
    CSV.generate do |csv|
      csv << Row.members
      rows.each { |row| csv << row.to_h.values }
    end
  end

  # parameters
  delegate :period, to: :context

  def call
    context.rows = Petasos::Client.order(:name).pluck(:id, :name).map { |id, name| row(id, name) }
  end

  private

  def row(id, name)
    members = members_by_client.fetch(id, [])
    logins = members.count { |_, _, last_login| period.cover?(last_login) }
    ask = members.sum { |_, email, _| ask_counts.fetch(email, 0) }
    reports = members.sum { |_, email, _| report_counts.fetch(email, 0) } - ask

    segment = segment(logins:, reports:, ask:)
    previous = previous_segments[id]

    Row.new(client_id: id, account: name, users: members.size, logins:, mercury_ai_reports: reports, ask_reports: ask,
            last_project: last_projects[id], segment:, previous_segment: previous,
            segment_change: change(previous, segment))
  end

  # Nil for an account with no earlier row to compare with.
  def change(previous, segment)
    return unless previous

    { 1 => :up, -1 => :down, 0 => :same }.fetch(SEGMENTS.index(segment) <=> SEGMENTS.index(previous))
  end

  def segment(logins:, reports:, ask:)
    if ask.positive? then :power
    elsif reports.positive? then :activated
    elsif logins.positive? then :active
    else :dormant
    end
  end

  # { client_id => [[client_id, email, last_login], ...] }. A user in several clients counts toward each.
  def members_by_client
    @members_by_client ||= Petasos::Membership.user_rows.uniq { |client_id, email, _| [client_id, email] }
                                              .group_by(&:first)
  end

  # { client_id => segment } recorded for the week before.
  def previous_segments
    @previous_segments ||= AccountWeek.where(week: period.begin.to_date - 1.week).pluck(:client_id, :segment)
                                      .to_h { |id, segment| [id, segment.to_sym] }
  end

  def report_counts
    @report_counts ||= Thoth::Completion.counts_by_email(period)
  end

  def ask_counts
    @ask_counts ||= Thoth::Completion.ask.counts_by_email(period)
  end

  def last_projects
    @last_projects ||= Petasos::Project.latest_numbers_by_client
  end
end
