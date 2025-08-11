class MarkingRulesController < ApplicationController
  before_action :set_assessment_and_scheme
  before_action :set_marking_rule, only: [:show, :edit, :update, :destroy, :move_up, :move_down]

  def index
    @marking_rules = @marking_scheme.assessment_question_marking_rules
      .includes(:assessment_question)
      .ordered
    @questions_without_rules = questions_without_rules
  end

  def show
  end

  def new
    @marking_rule = @marking_scheme.assessment_question_marking_rules.build
    @question = @assessment.assessment_questions.find(params[:question_id]) if params[:question_id]

    if @question
      @marking_rule.assessment_question = @question
      @marking_rule.rule_type = @question.default_marking_rule_type
      @marking_rule.points = calculate_default_points
      set_default_criteria
    end

    @available_questions = available_questions
    @rule_types = []
    @criteria_fields = []
  end

  def create
    @marking_rule = @marking_scheme.assessment_question_marking_rules.build(marking_rule_params)
    @marking_rule.order = next_order_number

    if @marking_rule.save
      # Update option points if provided and rule type is option_based
      if @marking_rule.rule_type == "option_based" && params[:option_points].present?
        update_option_points(params[:option_points])
      end

      redirect_to assessment_marking_scheme_marking_rule_path(@assessment, @marking_scheme, @marking_rule),
                  notice: "Marking rule was successfully created."
    else
      @available_questions = available_questions
      set_rule_types_and_criteria
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_questions = available_questions
    set_rule_types_and_criteria
  end

  def update
    if @marking_rule.update(marking_rule_params)
      # Update option points if provided and rule type is option_based
      if @marking_rule.rule_type == "option_based" && params[:option_points].present?
        update_option_points(params[:option_points])
      end

      redirect_to edit_assessment_marking_scheme_marking_rule_path(@assessment, @marking_scheme, @marking_rule),
                  notice: "Marking rule was successfully updated."
    else
      @available_questions = available_questions
      set_rule_types_and_criteria
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @marking_rule.destroy
    redirect_to assessment_marking_scheme_marking_rules_path(@assessment, @marking_scheme),
                notice: "Marking rule was successfully deleted."
  end

  def move_up
    @marking_rule.decrement!(:order) if @marking_rule.order > 1
    reorder_rules
    redirect_to assessment_marking_scheme_marking_rules_path(@assessment, @marking_scheme)
  end

  def move_down
    max_order = @marking_scheme.assessment_question_marking_rules.maximum(:order) || 0
    @marking_rule.increment!(:order) if @marking_rule.order < max_order
    reorder_rules
    redirect_to assessment_marking_scheme_marking_rules_path(@assessment, @marking_scheme)
  end

  def bulk_create
    questions_without_rules.each_with_index do |question, index|
      @marking_scheme.assessment_question_marking_rules.create!(
        assessment_question: question,
        rule_type: question.default_marking_rule_type,
        points: calculate_default_points,
        criteria: {},
        order: next_order_number + index,
      )
    end

    redirect_to assessment_marking_scheme_marking_rules_path(@assessment, @marking_scheme),
                notice: "Created #{questions_without_rules.count} marking rules."
  end

  # AJAX endpoint for getting rule types based on question
  def rule_types
    question = @assessment.assessment_questions.find(params[:question_id])
    rule_types = question.available_marking_rule_types.map do |rule_type_key|
      rule_type = RuleType.find_by_key(rule_type_key)
      {
        key: rule_type_key,
        name: rule_type&.name || rule_type_key.humanize,
        description: rule_type&.description_key ? I18n.t(rule_type.description_key, default: "") : "",
      }
    end

    render json: { rule_types: rule_types, default: question.default_marking_rule_type }
  end

  # AJAX endpoint for getting criteria fields based on rule type
  def criteria_fields
    rule_type = RuleType.find_by_key(params[:rule_type])
    criteria_fields = rule_type&.criteria_fields || []

    render json: { criteria_fields: criteria_fields }
  end

  private

  def set_assessment_and_scheme
    @assessment = Assessment.find(params[:assessment_id])
    @marking_scheme = @assessment.assessment_marking_schemes.find(params[:marking_scheme_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to assessments_path, alert: "Assessment or marking scheme not found."
  end

  def set_marking_rule
    @marking_rule = @marking_scheme.assessment_question_marking_rules.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to assessment_marking_scheme_marking_rules_path(@assessment, @marking_scheme),
                alert: "Marking rule not found."
  end

  def marking_rule_params
    params.require(:assessment_question_marking_rule).permit(
      :assessment_question_id, :rule_type, :points, :is_active, :order,
      criteria: {},
    )
  end

  def available_questions
    @assessment.assessment_questions.includes(:assessment_question_marking_rules)
  end

  def questions_without_rules
    @assessment.assessment_questions.where.not(
      id: @marking_scheme.assessment_question_marking_rules
        .select(:assessment_question_id),
    )
  end

  def calculate_default_points
    case @question&.type
    when "AssessmentQuestions::MultipleChoice", "AssessmentQuestions::Radio"
      10.0
    when "AssessmentQuestions::RichText"
      15.0
    when "AssessmentQuestions::RangeType", "AssessmentQuestions::DateType"
      5.0
    else
      10.0
    end
  end

  def set_default_criteria
    return unless @question && @marking_rule.rule_type

    rule_type = RuleType.find_by_key(@marking_rule.rule_type)
    return unless rule_type

    @marking_rule.criteria = {}
    rule_type.criteria_fields.each do |field|
      if field["default"]
        @marking_rule.criteria[field["name"]] = field["default"]
      end
    end
  end

  def set_rule_types_and_criteria
    if @marking_rule.assessment_question
      @rule_types = @marking_rule.assessment_question.available_marking_rule_types.map do |rule_type_key|
        rule_type = RuleType.find_by_key(rule_type_key)
        {
          key: rule_type_key,
          name: rule_type&.name || rule_type_key.humanize,
          description: rule_type&.description_key ? I18n.t(rule_type.description_key, default: "") : "",
        }
      end

      if @marking_rule.rule_type
        rule_type = RuleType.find_by_key(@marking_rule.rule_type)
        @criteria_fields = rule_type&.criteria_fields || []
      end
    end
  end

  def next_order_number
    (@marking_scheme.assessment_question_marking_rules.maximum(:order) || 0) + 1
  end

  def reorder_rules
    @marking_scheme.assessment_question_marking_rules.ordered.each_with_index do |rule, index|
      rule.update_column(:order, index + 1)
    end
  end

  def update_option_points(option_points_params)
    option_points_params.each do |option_id, option_data|
      option = AssessmentQuestionOption.find_by(id: option_id)
      if option && option.assessment_question_id == @marking_rule.assessment_question_id
        # Handle points - convert empty string to nil
        points_value = option_data[:points]
        points = (points_value.present? && points_value != "") ? points_value.to_f : nil

        # Handle checkbox - Rails sends "1" for checked, "0" for unchecked
        is_correct = option_data[:is_correct_answer].to_s == "1"

        # Enforce restriction: points only apply to correct answers
        option.is_correct_answer = is_correct
        option.points = is_correct ? points : 0
        option.save
      end
    end
  rescue ActiveRecord::RecordNotFound
    # Ignore missing options
  rescue => e
    Rails.logger.error "Error in update_option_points: #{e.message}"
  end
end
