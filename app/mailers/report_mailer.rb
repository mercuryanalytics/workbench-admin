# frozen_string_literal: true

class ReportMailer < ApplicationMailer
  def weekly(rows:, period:)
    @week = period.begin.to_date
    @counts = SegmentReport::SEGMENTS.reverse.index_with { |segment| rows.count { |row| row.segment == segment } }
    @moves = rows.map(&:segment_change).compact.tally.values_at(:up, :down)

    attachments["segments-#{@week}.csv"] = SegmentReport.csv(rows)
    mail to: ApplicationConfig.report_recipients, subject: "Platform engagement, week of #{@week}"
  end
end
