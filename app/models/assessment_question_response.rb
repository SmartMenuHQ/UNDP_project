# == Schema Information
#
# Table name: assessment_question_responses
#
#  id                             :bigint           not null, primary key
#  metadata                       :jsonb
#  value                          :jsonb
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  assessment_id                  :bigint           not null
#  assessment_question_id         :bigint           not null
#  assessment_response_session_id :bigint
#
# Indexes
#
#  idx_on_assessment_response_session_id_4618f6d7db               (assessment_response_session_id)
#  index_assessment_question_responses_on_assessment_id           (assessment_id)
#  index_assessment_question_responses_on_assessment_question_id  (assessment_question_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (assessment_question_id => assessment_questions.id)
#  fk_rails_...  (assessment_response_session_id => assessment_response_sessions.id)
#
class AssessmentQuestionResponse < ApplicationRecord
  belongs_to :assessment_question
  belongs_to :assessment
  belongs_to :assessment_response_session, optional: true

  has_many :selected_options, dependent: :destroy
  has_many :assessment_question_options, through: :selected_options
  has_many :assessment_response_scores, dependent: :destroy

  # Callbacks
  after_initialize :ensure_jsonb_initialized

  # Validations
  validates :assessment_question_id, uniqueness: { scope: :assessment_response_session_id,
                                                   message: "can only have one response per session" }

  validate :validate_using_validator

  # Store accessor for commonly used metadata
  store_accessor :metadata, :validation_errors, :custom_data

  def response_value
    case assessment_question.type
    when "AssessmentQuestions::MultipleChoice", "AssessmentQuestions::Radio", "AssessmentQuestions::BooleanType"
      selected_options.pluck(:assessment_question_option_id)
    else
      value
    end
  end

  def response_value=(new_value)
    case assessment_question.type
    when "AssessmentQuestions::MultipleChoice", "AssessmentQuestions::Radio", "AssessmentQuestions::BooleanType"
      set_selected_options(new_value)
    else
      self.value = new_value
    end
  end

  # Get display value for the response
  def display_value
    case assessment_question.type
    when "AssessmentQuestions::MultipleChoice", "AssessmentQuestions::Radio", "AssessmentQuestions::BooleanType"
      assessment_question_options.pluck(:text).join(", ")
    when "AssessmentQuestions::DateType"
      format_date_value
    when "AssessmentQuestions::RangeType"
      value&.dig("number") || value&.dig("rating") || value&.dig("range") || value
    when "AssessmentQuestions::FileUpload"
      value&.dig("filename") || "File uploaded"
    else
      value&.dig("text") || value
    end
  end

  # Check if response has a value
  def has_value?
    case assessment_question.type
    when "AssessmentQuestions::MultipleChoice", "AssessmentQuestions::Radio", "AssessmentQuestions::BooleanType"
      selected_options.exists?
    else
      value.present? && value != {}
    end
  end

  # Marking methods
  def score_for_scheme(scheme_id)
    assessment_response_scores.find_by(assessment_marking_scheme_id: scheme_id)
  end

  def total_score_earned_for_scheme(scheme_id)
    score_for_scheme(scheme_id)&.score_earned || 0
  end

  def grade_response(scheme_id)
    scheme = AssessmentMarkingScheme.find(scheme_id)
    scheme.grade_response(self)
  end

  private

  def ensure_jsonb_initialized
    self.value ||= {}
    self.metadata ||= {}
  end

  def set_selected_options(option_ids)
    return if option_ids.blank?

    option_ids = Array(option_ids).map(&:to_i).reject(&:zero?)

    if persisted?
      # For saved records, use create! and destroy_all
      transaction do
        selected_options.destroy_all
        option_ids.each do |option_id|
          selected_options.create!(assessment_question_option_id: option_id)
        end
      end
    else
      # For unsaved records, use build and clear
      selected_options.clear
      option_ids.each do |option_id|
        selected_options.build(assessment_question_option_id: option_id)
      end
    end
  end

  def validate_using_validator
    ResponseValidator.new(self).validate!
  end

  def format_date_value
    return nil unless value.present?

    case assessment_question.sub_type
    when "date"
      Date.parse(value["date"]).strftime("%B %d, %Y") rescue value["date"]
    when "datetime"
      DateTime.parse(value["datetime"]).strftime("%B %d, %Y at %I:%M %p") rescue value["datetime"]
    when "year"
      value["year"]
    when "time"
      Time.parse(value["time"]).strftime("%I:%M %p") rescue value["time"]
    when "month"
      Date.parse("#{value["month"]}-01").strftime("%B %Y") rescue value["month"]
    when "week"
      value["week"]
    when "date_range"
      range_val = value["date_range"]
      if range_val.is_a?(Hash) && range_val["start"] && range_val["end"]
        start_date = Date.parse(range_val["start"]).strftime("%B %d, %Y") rescue range_val["start"]
        end_date = Date.parse(range_val["end"]).strftime("%B %d, %Y") rescue range_val["end"]
        "#{start_date} - #{end_date}"
      else
        range_val
      end
    else
      value.values.first
    end
  rescue
    value.to_s
  end
end
