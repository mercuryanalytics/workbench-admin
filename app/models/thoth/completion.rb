# frozen_string_literal: true

module Thoth
  class Completion < Record
    ASK_MODELS = %w[
      AskMercuryAILiveLabs AskMercuryAILiveLabsReport
      AskMercuryAIQualAtScale AskMercuryAIQualAtScaleReport
      AskMercuryAITopline AskMercuryAIToplineReport
      M2mAskMercuryAIReport
    ].freeze

    MODEL = Arel::Nodes::InfixOperation.new("->>", arel_table[:metadata], Arel::Nodes.build_quoted("model"))
    EMAIL = Arel::Nodes::NamedFunction.new("lower", [arel_table[:user]])

    # A report is a finished deliverable; dependents are the pieces it was assembled from.
    scope :reports, -> { where(deliverable: true, status: "ready").where.not(user: nil) }
    scope :ask, -> { where(MODEL.in(ASK_MODELS)) }

    # { email => report count } for reports created in the period.
    def self.counts_by_email(period)
      reports.where(created_at: period).group(EMAIL).count
    end
  end
end
