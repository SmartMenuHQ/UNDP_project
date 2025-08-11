module ConditionalVisibility
  extend ActiveSupport::Concern

  included do
    # Store accessor for visibility conditions
    store_accessor :visibility_conditions,
      :trigger_question_id,        # ID of the question that triggers visibility
      :trigger_response_type,      # Type of response to check ('option_selected', 'value_equals', 'value_range', etc.)
      :trigger_values,             # Array of values/option IDs that trigger visibility
      :operator,                   # 'equals', 'not_equals', 'contains', 'greater_than', 'less_than', 'between'
      :logic_operator             # 'and', 'or' for multiple conditions

    # Scopes
    scope :conditional, -> { where(is_conditional: true) }
    scope :unconditional, -> { where(is_conditional: false) }
    scope :visible_for_session, ->(session) {
            where(
              "(is_conditional = false) OR (id IN (?))",
              conditionally_visible_ids_for_session(session)
            )
          }

    # Validations
    validates :trigger_question_id, presence: true, if: :is_conditional?
    validates :trigger_response_type, presence: true, if: :is_conditional?
    validates :trigger_values, presence: true, if: :is_conditional?
    validate :trigger_question_exists, if: :is_conditional?
    validate :trigger_question_precedes_current, if: :is_conditional?
  end

  class_methods do
    # Get IDs of conditionally visible items for a specific response session
    def conditionally_visible_ids_for_session(session)
      return [] unless session

      conditional_items = self.conditional.includes(:assessment)
      visible_ids = []

      conditional_items.each do |item|
        if item.visible_for_session?(session)
          visible_ids << item.id
        end
      end

      visible_ids
    end
  end

  # Check if this item should be visible for a given response session
  def visible_for_session?(session)
    return true unless is_conditional?
    return false unless session

    trigger_question = AssessmentQuestion.find_by(id: trigger_question_id)
    return false unless trigger_question

    # Get the response for the trigger question in this session
    trigger_response = session.assessment_question_responses
      .find_by(assessment_question: trigger_question)

    return false unless trigger_response

    evaluate_visibility_condition(trigger_response)
  end

  # Set up a simple condition based on selected options
  def add_option_condition(trigger_question_id, selected_option_ids, operator = "contains")
    self.is_conditional = true
    self.trigger_question_id = trigger_question_id
    self.trigger_response_type = "option_selected"
    self.trigger_values = Array(selected_option_ids).map(&:to_s)
    self.operator = operator
  end

  # Set up a condition based on text/numeric values
  def add_value_condition(trigger_question_id, values, operator = "equals")
    self.is_conditional = true
    self.trigger_question_id = trigger_question_id
    self.trigger_response_type = "value_equals"
    self.trigger_values = Array(values).map(&:to_s)
    self.operator = operator
  end

  # Set up a range condition for numeric values
  def add_range_condition(trigger_question_id, min_value, max_value)
    self.is_conditional = true
    self.trigger_question_id = trigger_question_id
    self.trigger_response_type = "value_range"
    self.trigger_values = [min_value.to_s, max_value.to_s]
    self.operator = "between"
  end

  # Remove conditional visibility
  def remove_conditions
    self.is_conditional = false
    self.visibility_conditions = {}
  end

  # Get human-readable description of the condition
  def condition_description
    return "Always visible" unless is_conditional?

    trigger_question = AssessmentQuestion.find_by(id: trigger_question_id)
    return "Invalid condition" unless trigger_question

    case trigger_response_type
    when "option_selected"
      option_texts = AssessmentQuestionOption.where(id: trigger_values).pluck(:text)
      "Visible when '#{trigger_question.text}' #{operator_description} #{option_texts.join(", ")}"
    when "value_equals"
      "Visible when '#{trigger_question.text}' #{operator_description} #{trigger_values.join(", ")}"
    when "value_range"
      "Visible when '#{trigger_question.text}' is between #{trigger_values[0]} and #{trigger_values[1]}"
    else
      "Custom condition on '#{trigger_question.text}'"
    end
  end

  private

  def evaluate_visibility_condition(trigger_response)
    case trigger_response_type
    when "option_selected"
      evaluate_option_condition(trigger_response)
    when "value_equals"
      evaluate_value_condition(trigger_response)
    when "value_range"
      evaluate_range_condition(trigger_response)
    else
      false
    end
  end

  def evaluate_option_condition(trigger_response)
    selected_option_ids = trigger_response.selected_options.pluck(:assessment_question_option_id).map(&:to_s)

    case operator
    when "contains", "any"
      (trigger_values & selected_option_ids).any?
    when "equals", "exact"
      selected_option_ids.sort == trigger_values.sort
    when "not_contains", "none"
      (trigger_values & selected_option_ids).empty?
    when "all"
      trigger_values.all? { |val| selected_option_ids.include?(val) }
    else
      false
    end
  end

  def evaluate_value_condition(trigger_response)
    response_value = extract_response_value(trigger_response)
    return false unless response_value

    case operator
    when "equals"
      trigger_values.include?(response_value.to_s)
    when "not_equals"
      !trigger_values.include?(response_value.to_s)
    when "contains"
      trigger_values.any? { |val| response_value.to_s.include?(val) }
    when "greater_than"
      response_value.to_f > trigger_values.first.to_f
    when "less_than"
      response_value.to_f < trigger_values.first.to_f
    else
      false
    end
  end

  def evaluate_range_condition(trigger_response)
    response_value = extract_response_value(trigger_response)
    return false unless response_value

    min_val = trigger_values[0].to_f
    max_val = trigger_values[1].to_f
    response_value.to_f >= min_val && response_value.to_f <= max_val
  end

  def extract_response_value(trigger_response)
    # Handle different response value formats
    if trigger_response.value.is_a?(Hash)
      trigger_response.value["value"] || trigger_response.value[:value]
    else
      trigger_response.value
    end
  end

  def operator_description
    case operator
    when "contains", "any"
      "includes any of"
    when "equals", "exact"
      "equals exactly"
    when "not_contains", "none"
      "does not include any of"
    when "all"
      "includes all of"
    when "not_equals"
      "does not equal"
    when "greater_than"
      "is greater than"
    when "less_than"
      "is less than"
    when "between"
      "is between"
    else
      operator
    end
  end

  def trigger_question_exists
    return unless trigger_question_id.present?

    unless AssessmentQuestion.exists?(trigger_question_id)
      errors.add(:trigger_question_id, "does not exist")
    end
  end

  def trigger_question_precedes_current
    return unless trigger_question_id.present?

    trigger_question = AssessmentQuestion.find_by(id: trigger_question_id)
    return unless trigger_question

    # For questions: trigger must be in earlier section or earlier in same section
    if self.is_a?(AssessmentQuestion)
      if trigger_question.assessment_section_id == self.assessment_section_id
        # Same section: trigger must have lower order
        if trigger_question.order >= self.order
          errors.add(:trigger_question_id, "must come before this question in the same section")
        end
      else
        # Different section: trigger section must have lower order
        trigger_section_order = trigger_question.assessment_section.order
        current_section_order = self.assessment_section.order

        if trigger_section_order >= current_section_order
          errors.add(:trigger_question_id, "must be in an earlier section")
        end
      end
    end

    # For sections: trigger question must be in an earlier section
    if self.is_a?(AssessmentSection)
      trigger_section_order = trigger_question.assessment_section.order

      if trigger_section_order >= self.order
        errors.add(:trigger_question_id, "must be in an earlier section")
      end
    end
  end
end
