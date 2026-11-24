# frozen_string_literal: true

# One row per petasos client, and under it one row per member, built from the members' activity in the period. Users are
# matched to thoth by email. An account's counts are the sums of its members', and its segment is its most engaged
# member's.
class SegmentReport
  include Interactor

  # Least to most engaged; a segment change is a move along this order.
  SEGMENTS = %i[dormant active activated power].freeze

  Row = Data.define(:client_id, :account, :users, :logins, :mercury_ai_reports, :ask_reports, :last_project, :segment,
                    :previous_segment, :segment_change)

  # A member's week. `logins` is 0 or 1 because petasos keeps only the latest login; `last_login` is that date, which
  # also shows whether the user has ever logged in.
  UserRow = Data.define(:client_id, :account, :user, :last_login, :logins, :mercury_ai_reports, :ask_reports, :segment)

  COLUMNS = %i[level client_id account user users last_login logins mercury_ai_reports ask_reports last_project segment
               previous_segment segment_change].freeze

  FORMULA_START = /\A[=+\-@\t\r]/

  # Each account row is followed by its members' rows.
  def self.csv(rows, user_rows)
    users = user_rows.group_by(&:client_id)
    CSV.generate do |csv|
      csv << COLUMNS
      rows.each do |row|
        csv << line(:account, row)
        users.fetch(row.client_id, []).each { |user| csv << line(:user, user) }
      end
    end
  end

  def self.line(level, row)
    attributes = row.to_h.merge(level:)
    COLUMNS.map { |column| spreadsheet_safe(attributes[column]) }
  end

  # Account names and project numbers are free text, and a spreadsheet runs a cell starting with one of these as a
  # formula. The leading quote makes it plain text.
  def self.spreadsheet_safe(value)
    value.is_a?(String) && value.match?(FORMULA_START) ? "'#{value}" : value
  end

  # parameters
  delegate :period, to: :context

  def call
    clients = Petasos::Client.order(:name).pluck(:id, :name)
    users = clients.to_h { |id, name| [id, user_rows(id, name)] }
    context.rows = clients.map { |id, name| row(id, name, users.fetch(id)) }
    context.user_rows = users.values.flatten
  end

  private

  def user_rows(id, name)
    members_by_client.fetch(id, []).sort_by { |_, email, _| email }.map do |_, email, last_login|
      ask = ask_counts.fetch(email, 0)
      reports = report_counts.fetch(email, 0) - ask
      logins = period.cover?(last_login) ? 1 : 0

      UserRow.new(client_id: id, account: name, user: email, last_login: last_login&.in_time_zone&.to_date, logins:,
                  mercury_ai_reports: reports, ask_reports: ask, segment: segment(logins:, reports:, ask:))
    end
  end

  def row(id, name, users)
    logins, reports, ask = %i[logins mercury_ai_reports ask_reports].map { |count| users.sum(&count) }
    segment = segment(logins:, reports:, ask:)
    previous = previous_segments[id]

    Row.new(client_id: id, account: name, users: users.size, logins:, mercury_ai_reports: reports, ask_reports: ask,
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
