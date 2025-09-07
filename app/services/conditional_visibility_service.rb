class ConditionalVisibilityService
  attr_reader :assessment

  def initialize(assessment)
    @assessment = assessment
  end

  # Set up a condition where a question/section is visible when specific options are selected
  def create_option_condition(target, trigger_question_id, selected_option_ids, operator = "contains")
    validate_target(target)
    validate_trigger_question(trigger_question_id)

    target.add_option_condition(trigger_question_id, selected_option_ids, operator)
    target.save!

    target
  end

  # Set up a condition where a question/section is visible when a text/numeric value matches
  def create_value_condition(target, trigger_question_id, values, operator = "equals")
    validate_target(target)
    validate_trigger_question(trigger_question_id)

    target.add_value_condition(trigger_question_id, values, operator)
    target.save!

    target
  end

  # Set up a range condition for numeric values
  def create_range_condition(target, trigger_question_id, min_value, max_value)
    validate_target(target)
    validate_trigger_question(trigger_question_id)

    target.add_range_condition(trigger_question_id, min_value, max_value)
    target.save!

    target
  end

  # Remove all conditions from a target
  def remove_conditions(target)
    validate_target(target)

    target.remove_conditions
    target.save!

    target
  end

  # Get all questions that can be used as triggers for a given target
  def available_trigger_questions(target)
    validate_target(target)

    if target.is_a?(AssessmentQuestion)
      # For questions: can use questions from earlier sections or earlier in same section
      same_section_questions = target.assessment_section.assessment_questions
                                     .where('"order" < ?', target.order)

      earlier_section_questions = assessment.assessment_questions
                                            .joins(:assessment_section)
                                            .where("assessment_sections.order < ?", target.assessment_section.order)

      # Combine the two queries using UNION to avoid pluck issues with joins
      same_section_ids = same_section_questions.select(:id)
      earlier_section_ids = earlier_section_questions.select(:id)

      AssessmentQuestion.where(id: same_section_ids).or(AssessmentQuestion.where(id: earlier_section_ids))
    elsif target.is_a?(AssessmentSection)
      # For sections: can use questions from earlier sections only
      assessment.assessment_questions
                .joins(:assessment_section)
                .where("assessment_sections.order < ?", target.order)
    else
      AssessmentQuestion.none
    end
  end

  # Get summary of all conditional items in the assessment
  def conditional_summary
    {
      conditional_questions: assessment.assessment_questions.conditional.count,
      conditional_sections: assessment.assessment_sections.conditional.count,
      total_questions: assessment.assessment_questions.count,
      total_sections: assessment.assessment_sections.count,
      conditions: build_conditions_list,
    }
  end

  # Test visibility for a specific session
  def test_visibility_for_session(session)
    return { visible_sections: [], visible_questions: [], hidden_sections: [], hidden_questions: [] } if session.nil?

    visible_questions = session.visible_questions
    hidden_questions = assessment.assessment_questions.where.not(id: visible_questions.pluck(:id))

    {
      visible_sections: session.visible_sections.pluck(:id, :name),
      visible_questions: visible_questions.map { |q| [q.id, extract_question_text(q)] },
      hidden_sections: assessment.assessment_sections.where.not(id: session.visible_sections.pluck(:id)).pluck(:id, :name),
      hidden_questions: hidden_questions.map { |q| [q.id, extract_question_text(q)] },
    }
  end

  # Validate that responses don't break conditional logic
  def validate_conditional_integrity(session)
    errors = []

    # Check if any visible items depend on responses that are no longer visible
    assessment.assessment_questions.conditional.each do |question|
      next unless question.visible_for_session?(session)

      trigger_question = AssessmentQuestion.find_by(id: question.trigger_question_id)
      next unless trigger_question

      unless trigger_question.visible_for_session?(session)
        errors << "Question '#{extract_question_text(question)}' depends on '#{extract_question_text(trigger_question)}' which is no longer visible"
      end
    end

    assessment.assessment_sections.conditional.each do |section|
      next unless section.visible_for_session?(session)

      trigger_question = AssessmentQuestion.find_by(id: section.trigger_question_id)
      next unless trigger_question

      unless trigger_question.visible_for_session?(session)
        errors << "Section '#{section.name}' depends on '#{extract_question_text(trigger_question)}' which is no longer visible"
      end
    end

    errors
  end

  # Get dependency graph for visualization
  def dependency_graph
    nodes = []
    edges = []

    # Add all questions as nodes
    assessment.assessment_questions.each do |question|
      nodes << {
        id: "q_#{question.id}",
        label: extract_question_text(question).truncate(50),
        type: "question",
        conditional: question.is_conditional?,
        section_id: question.assessment_section_id,
      }
    end

    # Add all sections as nodes
    assessment.assessment_sections.each do |section|
      nodes << {
        id: "s_#{section.id}",
        label: section.name,
        type: "section",
        conditional: section.is_conditional?,
      }
    end

    # Add conditional relationships as edges
    assessment.assessment_questions.conditional.each do |question|
      trigger_question = AssessmentQuestion.find_by(id: question.trigger_question_id)
      next unless trigger_question

      edges << {
        from: "q_#{trigger_question.id}",
        to: "q_#{question.id}",
        label: question.operator_description,
        type: "question_to_question",
      }
    end

    assessment.assessment_sections.conditional.each do |section|
      trigger_question = AssessmentQuestion.find_by(id: section.trigger_question_id)
      next unless trigger_question

      edges << {
        from: "q_#{trigger_question.id}",
        to: "s_#{section.id}",
        label: section.operator_description,
        type: "question_to_section",
      }
    end

    { nodes: nodes, edges: edges }
  end

  private

  def extract_question_text(question)
    if question.text.is_a?(Hash)
      question.text["en"] || question.text.values.first || "Question"
    else
      question.text || "Question"
    end
  end

  def validate_target(target)
    unless target.is_a?(AssessmentQuestion) || target.is_a?(AssessmentSection)
      raise ArgumentError, "Target must be an AssessmentQuestion or AssessmentSection"
    end

    unless target.assessment_id == assessment.id
      raise ArgumentError, "Target does not belong to this assessment"
    end
  end

  def validate_trigger_question(trigger_question_id)
    trigger_question = AssessmentQuestion.find_by(id: trigger_question_id)

    unless trigger_question
      raise ArgumentError, "Trigger question not found"
    end

    unless trigger_question.assessment_id == assessment.id
      raise ArgumentError, "Trigger question does not belong to this assessment"
    end
  end

  def build_conditions_list
    conditions = []

    assessment.assessment_questions.conditional.includes(:assessment_section).each do |question|
      conditions << {
        type: "question",
        target: extract_question_text(question).truncate(50),
        target_id: question.id,
        section: question.assessment_section.name,
        description: question.condition_description,
      }
    end

    assessment.assessment_sections.conditional.each do |section|
      conditions << {
        type: "section",
        target: section.name,
        target_id: section.id,
        section: nil,
        description: section.condition_description,
      }
    end

    conditions
  end
end
