class Api::V1::Admin::MarkingRulesController < Api::V1::Admin::BaseController
  before_action :set_assessment
  before_action :set_marking_scheme
  before_action :set_marking_rule, only: [:show, :update, :destroy]

  # GET /api/v1/admin/assessments/:assessment_id/marking-schemes/:marking_scheme_id/rules
  def index
    authorize @assessment, :manage_marking?

    rules = @marking_scheme.assessment_question_marking_rules
      .includes(:assessment_question)
      .ordered

    # Filters
    rules = rules.where(is_active: ActiveModel::Type::Boolean.new.cast(params[:is_active])) if params.key?(:is_active)
    rules = rules.where(assessment_question_id: params[:question_id]) if params[:question_id].present?

    # Pagination
    page = params[:page].presence || 1
    per_page = [params[:per_page].to_i, 100].min
    per_page = 25 if per_page <= 0
    rules = rules.page(page).per(per_page) if defined?(Kaminari)

    @data = {
      marking_rules: rules,
      total_count: @marking_scheme.assessment_question_marking_rules.count,
      active_count: @marking_scheme.assessment_question_marking_rules.where(is_active: true).count,
      pagination: {
        current_page: page.to_i,
        per_page: per_page,
        total_pages: (@marking_scheme.assessment_question_marking_rules.count.to_f / per_page).ceil,
      },
      assessment: { id: @assessment.id, title: @assessment.title },
      marking_scheme: { id: @marking_scheme.id, name: @marking_scheme.name },
    }

    note!("Marking rules retrieved successfully")
  end

  # GET /api/v1/admin/assessments/:assessment_id/marking-schemes/:marking_scheme_id/rules/:id
  def show
    authorize @assessment, :manage_marking?
    @data = { marking_rule: @marking_rule }
    note!("Marking rule retrieved successfully")
  end

  # POST /api/v1/admin/assessments/:assessment_id/marking-schemes/:marking_scheme_id/rules
  def create
    authorize @assessment, :manage_marking?

    question = @assessment.assessment_questions.find(marking_rule_params[:assessment_question_id])

    rule = @marking_scheme.assessment_question_marking_rules.new(marking_rule_params)
    rule.order = next_order_number

    # Default rule_type and points if omitted
    rule.rule_type ||= question.default_marking_rule_type
    rule.points ||= calculate_default_points_for(question)
    rule.criteria ||= {}

    if rule.save
      @data = { marking_rule: rule }
      note!("Marking rule created successfully")
      render :create, status: :ok
    else
      raise ApiException::ValidationError.new("Marking rule creation failed",
                                              details: { errors: rule.errors.full_messages })
    end
  end

  # PATCH/PUT /api/v1/admin/assessments/:assessment_id/marking-schemes/:marking_scheme_id/rules/:id
  def update
    authorize @assessment, :manage_marking?

    if @marking_rule.update(marking_rule_params)
      @data = { marking_rule: @marking_rule }
      note!("Marking rule updated successfully")
      render :update, status: :ok
    else
      raise ApiException::ValidationError.new("Marking rule update failed",
                                              details: { errors: @marking_rule.errors.full_messages })
    end
  end

  # DELETE /api/v1/admin/assessments/:assessment_id/marking-schemes/:marking_scheme_id/rules/:id
  def destroy
    authorize @assessment, :manage_marking?

    if @marking_rule.destroy
      @data = { deleted_id: @marking_rule.id }
      note!("Marking rule deleted successfully")
      render :destroy, status: :ok
    else
      raise ApiException::ValidationError.new("Marking rule deletion failed",
                                              details: { errors: @marking_rule.errors.full_messages })
    end
  end

  # POST /api/v1/admin/assessments/:assessment_id/marking-schemes/:marking_scheme_id/rules/bulk-create
  def bulk_create
    authorize @assessment, :manage_marking?

    created = 0
    rules = []

    questions_without_rules.each_with_index do |question, index|
      rule = @marking_scheme.assessment_question_marking_rules.build(
        assessment_question: question,
        rule_type: question.default_marking_rule_type,
        points: calculate_default_points_for(question),
        criteria: {},
        order: next_order_number + index,
      )
      if rule.save
        created += 1
        rules << rule
      end
    end

    @data = { created_count: created, marking_rules: rules }
    note!("Created #{created} marking rules")
  end

  # GET /api/v1/admin/assessments/:assessment_id/marking-schemes/:marking_scheme_id/rules/rule-types
  def rule_types
    authorize @assessment, :manage_marking?
    question = @assessment.assessment_questions.find(params[:question_id])

    rule_types = question.available_marking_rule_types.map do |rule_type_key|
      rule_type = RuleType.find_by_key(rule_type_key)
      {
        key: rule_type_key,
        name: rule_type&.name || rule_type_key.humanize,
        description: rule_type&.description_key ? I18n.t(rule_type.description_key, default: "") : "",
      }
    end

    @data = { rule_types: rule_types, default: question.default_marking_rule_type }
    note!("Rule types retrieved successfully")
  end

  # GET /api/v1/admin/assessments/:assessment_id/marking-schemes/:marking_scheme_id/rules/criteria-fields
  def criteria_fields
    authorize @assessment, :manage_marking?

    rule_type = RuleType.find_by_key(params[:rule_type])
    fields = rule_type&.criteria_fields || []

    @data = { criteria_fields: fields }
    note!("Criteria fields retrieved successfully")
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:assessment_id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Assessment not found")
  end

  def set_marking_scheme
    @marking_scheme = @assessment.assessment_marking_schemes.find(params[:marking_scheme_id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Marking scheme not found")
  end

  def set_marking_rule
    @marking_rule = @marking_scheme.assessment_question_marking_rules.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Marking rule not found")
  end

  def marking_rule_params
    params.require(:marking_rule).permit(:assessment_question_id, :rule_type, :points, :is_active, :order, criteria: {})
  end

  def next_order_number
    (@marking_scheme.assessment_question_marking_rules.maximum(:order) || 0) + 1
  end

  def calculate_default_points_for(question)
    case question&.type
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

  def questions_without_rules
    @assessment.assessment_questions.where.not(
      id: @marking_scheme.assessment_question_marking_rules.select(:assessment_question_id),
    )
  end
end
