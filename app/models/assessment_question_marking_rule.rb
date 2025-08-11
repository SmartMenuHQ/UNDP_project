# == Schema Information
#
# Table name: assessment_question_marking_rules
#
#  id                           :bigint           not null, primary key
#  criteria                     :jsonb
#  is_active                    :boolean          default(TRUE)
#  order                        :integer          default(0)
#  points                       :decimal(10, 2)   default(0.0)
#  rule_type                    :string           not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  assessment_marking_scheme_id :bigint           not null
#  assessment_question_id       :bigint           not null
#
# Indexes
#
#  idx_on_assessment_marking_scheme_id_ac1d6c24c2        (assessment_marking_scheme_id)
#  idx_on_assessment_question_id_229c1b774d              (assessment_question_id)
#  index_assessment_question_marking_rules_on_is_active  (is_active)
#  index_assessment_question_marking_rules_on_order      (order)
#  index_assessment_question_marking_rules_on_rule_type  (rule_type)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_marking_scheme_id => assessment_marking_schemes.id)
#  fk_rails_...  (assessment_question_id => assessment_questions.id)
#
class AssessmentQuestionMarkingRule < ApplicationRecord
  belongs_to :assessment_question
  belongs_to :assessment_marking_scheme
  has_many :assessment_response_scores, dependent: :destroy

  validates :rule_type, presence: true, inclusion: {
                          in: %w[
                            option_based range_based exact_match partial_match keyword_based
                            format_based step_based tolerance_based date_range_based
                            time_based overlap_based file_based size_based type_based
                            content_based strength_based content_analysis
                          ],
                        }
  validates :points, numericality: { greater_than_or_equal_to: 0 },
                     if: -> { !option_based? }

  store_accessor :criteria, :expected_values, :tolerance, :case_sensitive,
                 :partial_match_threshold, :date_format, :file_criteria,
                 :keywords, :format_pattern, :step_intervals, :strength_criteria,
                 :content_analysis_rules, :overlap_threshold

  # Auto-set rule type based on question type
  before_validation :set_default_rule_type, if: :new_record?
  validate :rule_type_compatibility_with_question

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:order) }

  def option_based?
    rule_type == "option_based"
  end

  def range_based?
    rule_type == "range_based"
  end

  def text_based?
    %w[exact_match partial_match keyword_based format_based].include?(rule_type)
  end

  def date_based?
    %w[date_range_based time_based overlap_based].include?(rule_type)
  end

  def file_based?
    %w[file_based size_based type_based content_based].include?(rule_type)
  end

  def evaluate_response(response)
    case rule_type
    when "option_based"
      evaluate_option_based_response(response)
    when "range_based"
      evaluate_range_based_response(response)
    when "exact_match"
      evaluate_exact_match_response(response)
    when "partial_match"
      evaluate_partial_match_response(response)
    when "keyword_based"
      evaluate_keyword_based_response(response)
    when "format_based"
      evaluate_format_based_response(response)
    when "step_based"
      evaluate_step_based_response(response)
    when "tolerance_based"
      evaluate_tolerance_based_response(response)
    when "date_range_based"
      evaluate_date_range_response(response)
    when "time_based"
      evaluate_time_based_response(response)
    when "overlap_based"
      evaluate_overlap_based_response(response)
    when "file_based"
      evaluate_file_based_response(response)
    when "size_based"
      evaluate_size_based_response(response)
    when "type_based"
      evaluate_type_based_response(response)
    when "content_based"
      evaluate_content_based_response(response)
    when "strength_based"
      evaluate_strength_based_response(response)
    when "content_analysis"
      evaluate_content_analysis_response(response)
    else
      0
    end
  end

  private

  def set_default_rule_type
    self.rule_type ||= assessment_question.default_marking_rule_type
  end

  def rule_type_compatibility_with_question
    available_types = assessment_question.available_marking_rule_types
    unless available_types.include?(rule_type)
      errors.add(:rule_type, "is not compatible with this question type. Available types: #{available_types.join(", ")}")
    end
  end

  # Enhanced evaluation methods for different rule types

  def evaluate_option_based_response(response)
    selected_options = response.selected_options.includes(:assessment_question_option)
    total_points = 0

    selected_options.each do |selected|
      option = selected.assessment_question_option

      # Only allocate points for options that are marked as correct answers
      next unless option.correct_answer?

      if option.has_assigned_points?
        # Count explicit points (can be positive or negative) only for correct answers
        total_points += option.points
      else
        # If no points assigned but marked as correct, award default points from rule
        total_points += (points || 1.0)
      end
    end

    # Apply minimum score clamp if configured
    if criteria["minimum_score"] && total_points < criteria["minimum_score"]
      total_points = criteria["minimum_score"]
    end

    total_points
  end

  def evaluate_range_based_response(response)
    value = extract_numeric_value(response)
    min = criteria["min"]
    max = criteria["max"]
    tolerance = criteria["tolerance"] || 0

    return 0 unless value && min && max

    if value >= (min - tolerance) && value <= (max + tolerance)
      points
    else
      0
    end
  end

  def evaluate_exact_match_response(response)
    response_value = extract_text_value(response)
    expected_values = criteria["expected_values"] || []

    return 0 unless response_value && expected_values.any?

    response_value = response_value.strip if criteria["trim_whitespace"]
    response_value = response_value.downcase unless criteria["case_sensitive"]

    expected_values.each do |expected|
      expected = expected.strip if criteria["trim_whitespace"]
      expected = expected.downcase unless criteria["case_sensitive"]

      return points if response_value == expected
    end

    0
  end

  def evaluate_partial_match_response(response)
    response_value = extract_text_value(response)
    expected_phrases = criteria["expected_values"] || []
    threshold = criteria["partial_match_threshold"] || 0.7

    return 0 unless response_value && expected_phrases.any?

    total_similarity = 0
    expected_phrases.each do |phrase|
      similarity = calculate_similarity(response_value, phrase)
      total_similarity = [total_similarity, similarity].max
    end

    if total_similarity >= threshold
      if criteria["scoring_method"] == "proportional"
        (total_similarity * points).round(2)
      else
        points
      end
    else
      0
    end
  end

  def evaluate_keyword_based_response(response)
    response_value = extract_text_value(response)
    keywords = criteria["keywords"] || []

    return 0 unless response_value && keywords.any?

    found_keywords = keywords.select { |keyword|
      response_value.downcase.include?(keyword.downcase)
    }

    if criteria["scoring_method"] == "proportional"
      (found_keywords.size.to_f / keywords.size * points).round(2)
    else
      found_keywords.any? ? points : 0
    end
  end

  def evaluate_format_based_response(response)
    response_value = extract_text_value(response)
    format_pattern = criteria["format_pattern"]

    return 0 unless response_value

    case assessment_question.sub_type
    when "email"
      return points if response_value.match?(URI::MailTo::EMAIL_REGEXP)
    when "url"
      return points if response_value.match?(URI.regexp(["http", "https"]))
    when "phone"
      phone_pattern = criteria["phone_pattern"] || /\A[\d\s\-\+\(\)]+\z/
      return points if response_value.match?(phone_pattern)
    else
      return points if format_pattern && response_value.match?(Regexp.new(format_pattern))
    end

    0
  end

  def evaluate_step_based_response(response)
    value = extract_numeric_value(response)
    step_intervals = criteria["step_intervals"] || []

    return 0 unless value && step_intervals.any?

    step_intervals.each do |interval|
      if value >= interval["min"] && value <= interval["max"]
        return interval["points"] || points
      end
    end

    0
  end

  def evaluate_tolerance_based_response(response)
    value = extract_numeric_value(response)
    expected_value = criteria["expected_value"]
    tolerance = criteria["tolerance"] || 0

    return 0 unless value && expected_value

    if (value - expected_value).abs <= tolerance
      points
    else
      0
    end
  end

  def evaluate_date_range_response(response)
    response_date = parse_date_value(response)
    start_date = parse_date(criteria["start_date"])
    end_date = parse_date(criteria["end_date"])

    return 0 unless response_date && start_date && end_date

    if response_date >= start_date && response_date <= end_date
      points
    else
      0
    end
  end

  def evaluate_time_based_response(response)
    response_time = parse_time_value(response)
    expected_time = parse_time(criteria["expected_time"])
    time_tolerance = criteria["time_tolerance"] || 0

    return 0 unless response_time && expected_time

    if (response_time - expected_time).abs <= time_tolerance
      points
    else
      0
    end
  end

  def evaluate_overlap_based_response(response)
    response_range = parse_date_range_value(response)
    expected_range = {
      start: parse_date(criteria["start_date"]),
      end: parse_date(criteria["end_date"]),
    }

    return 0 unless response_range && expected_range[:start] && expected_range[:end]

    overlap_start = [response_range[:start], expected_range[:start]].max
    overlap_end = [response_range[:end], expected_range[:end]].min

    if overlap_start <= overlap_end
      overlap_days = (overlap_end - overlap_start).to_i
      total_days = (expected_range[:end] - expected_range[:start]).to_i

      if criteria["scoring_method"] == "proportional"
        (overlap_days.to_f / total_days * points).round(2)
      else
        points
      end
    else
      0
    end
  end

  def evaluate_file_based_response(response)
    file_data = response.value
    return 0 unless file_data

    file_criteria = criteria["file_criteria"] || {}

    # Check file type
    if file_criteria["allowed_types"]
      file_type = file_data["content_type"]
      return 0 unless file_criteria["allowed_types"].include?(file_type)
    end

    # Check file size
    if file_criteria["max_size"]
      file_size = file_data["size"]
      return 0 if file_size > file_criteria["max_size"]
    end

    points
  end

  def evaluate_size_based_response(response)
    file_data = response.value
    max_size = criteria["max_size"]

    return 0 unless file_data && max_size

    file_size = file_data["size"]
    file_size <= max_size ? points : 0
  end

  def evaluate_type_based_response(response)
    file_data = response.value
    allowed_types = criteria["allowed_types"] || []

    return 0 unless file_data && allowed_types.any?

    file_type = file_data["content_type"]
    allowed_types.include?(file_type) ? points : 0
  end

  def evaluate_content_based_response(response)
    # Placeholder for content-based file evaluation
    # This would involve analyzing file content
    points
  end

  def evaluate_strength_based_response(response)
    response_value = extract_text_value(response)
    strength_criteria = criteria["strength_criteria"] || {}

    return 0 unless response_value

    score = 0
    score += points * 0.25 if response_value.length >= (strength_criteria["min_length"] || 8)
    score += points * 0.25 if response_value.match?(/[A-Z]/) # Has uppercase
    score += points * 0.25 if response_value.match?(/[a-z]/) # Has lowercase
    score += points * 0.25 if response_value.match?(/\d/) # Has number

    score.round(2)
  end

  def evaluate_content_analysis_response(response)
    response_value = extract_text_value(response)
    analysis_rules = criteria["content_analysis_rules"] || []

    return 0 unless response_value && analysis_rules.any?

    score = 0
    total_possible = 0

    analysis_rules.each do |rule|
      case rule["type"]
      when "word_count"
        word_count = response_value.split.size
        if word_count >= rule["min"] && word_count <= rule["max"]
          score += rule["points"]
        end
        total_possible += rule["points"]
      when "sentence_count"
        sentence_count = response_value.split(/[.!?]+/).size
        if sentence_count >= rule["min"] && sentence_count <= rule["max"]
          score += rule["points"]
        end
        total_possible += rule["points"]
      when "paragraph_count"
        paragraph_count = response_value.split(/\n\s*\n/).size
        if paragraph_count >= rule["min"] && paragraph_count <= rule["max"]
          score += rule["points"]
        end
        total_possible += rule["points"]
      end
    end

    total_possible > 0 ? score : 0
  end

  # Helper methods for value extraction and parsing
  def extract_numeric_value(response)
    case response.assessment_question.type
    when "AssessmentQuestions::RangeType"
      response.value&.dig("number") || response.value&.dig("rating")
    else
      response.value&.dig("number")
    end
  end

  def extract_text_value(response)
    case response.assessment_question.type
    when "AssessmentQuestions::RichText"
      response.value&.dig("text")
    else
      response.value&.dig("text") || response.value
    end
  end

  def parse_date_value(response)
    date_str = response.value&.dig("date")
    parse_date(date_str) if date_str
  end

  def parse_date_range_value(response)
    start_date = parse_date(response.value&.dig("start_date"))
    end_date = parse_date(response.value&.dig("end_date"))

    return nil unless start_date && end_date
    { start: start_date, end: end_date }
  end

  def parse_time_value(response)
    time_str = response.value&.dig("time")
    parse_time(time_str) if time_str
  end

  def parse_date(date_str)
    Date.parse(date_str) rescue nil
  end

  def parse_time(time_str)
    Time.parse(time_str) rescue nil
  end

  def calculate_similarity(text1, text2)
    words1 = text1.downcase.split(/\W+/)
    words2 = text2.downcase.split(/\W+/)

    intersection = words1 & words2
    union = words1 | words2

    union.empty? ? 0 : intersection.size.to_f / union.size
  end
end
