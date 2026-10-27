# frozen_string_literal: true

namespace :report do
  desc "Segment every account for a week (default: the week that ended yesterday), record it, write a CSV and mail it"
  task :weekly, %i[date] => :environment do |_, args|
    period = args[:date] ? Date.parse(args[:date]).in_time_zone.all_week : Time.current.yesterday.all_week
    rows = SegmentReport.call(period:).rows
    week = period.begin.to_date
    AccountWeek.record(rows, week:)
    AccountWeek.prune(week:, keep: ApplicationConfig.report_weeks_retained)

    path = Rails.root.join("tmp/reports/segments-#{period.begin.to_date}.csv")
    FileUtils.mkdir_p(path.dirname)
    path.write(SegmentReport.csv(rows))
    ReportMailer.weekly(rows:, period:).deliver_now
    puts path
  end
end
