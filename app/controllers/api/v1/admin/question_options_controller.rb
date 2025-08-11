class Api::V1::Admin::QuestionOptionsController < Api::V1::Admin::BaseController
  before_action :set_question
  before_action :set_option, only: [:show, :update, :destroy]

  # GET /api/v1/admin/questions/:question_id/options
  def index
    authorize @question.assessment, :manage_questions?

    @options = @question.assessment_question_options.order(:order)

    # Apply filtering
    @options = @options.where(is_correct_answer: params[:is_correct]) if params[:is_correct].present?

    # Apply search
    if params[:search].present?
      @options = @options.where("text ->> 'en' ILIKE ?", "%#{params[:search]}%")
    end

    # Apply sorting
    sort_by = params[:sort_by].presence || "order"
    sort_order = params[:sort_order].presence || "asc"
    # Quote the column name to handle reserved keywords like 'order'
    @options = @options.order("\"#{sort_by}\" #{sort_order}")

    @data = {
      options: @options,
      total_count: @question.assessment_question_options.count,
      question: {
        id: @question.id,
        text: @question.text,
        type: @question.type,
      },
      section: {
        id: @question.assessment_section.id,
        name: @question.assessment_section.name,
      },
      assessment: {
        id: @question.assessment.id,
        title: @question.assessment.title,
      },
      statistics: {
        total_options: @question.assessment_question_options.count,
        correct_options: @question.assessment_question_options.where(is_correct_answer: true).count,
        options_with_points: @question.assessment_question_options.where.not(points: 0).count,
      },
    }

    note!("Question options retrieved successfully")
  end

  # GET /api/v1/admin/questions/:question_id/options/:id
  def show
    authorize @question.assessment, :manage_questions?

    @data = {
      option: @option,
      question: {
        id: @question.id,
        text: @question.text,
        type: @question.type,
      },
      section: {
        id: @question.assessment_section.id,
        name: @question.assessment_section.name,
      },
      assessment: {
        id: @question.assessment.id,
        title: @question.assessment.title,
      },
      statistics: {
        selections_count: @option.selected_options.count,
        selection_percentage: calculate_selection_percentage(@option),
      },
    }

    note!("Question option retrieved successfully")
  end

  # POST /api/v1/admin/questions/:question_id/options
  def create
    authorize @question.assessment, :manage_questions?

    # Validate question type supports options
    unless @question.type.in?(["AssessmentQuestions::MultipleChoice", "AssessmentQuestions::Radio"])
      raise ApiException::ValidationError.new("Question type '#{@question.type}' does not support options")
    end

    @option = @question.assessment_question_options.build(option_params)
    @option.assessment = @question.assessment

    # Set order if not provided
    if @option.order.blank?
      @option.order = @question.assessment_question_options.maximum(:order).to_i + 1
    end

    if @option.save
      @data = { option: @option }
      note!("Question option created successfully")
    else
      raise ApiException::ValidationError.new("Option creation failed",
                                              details: { errors: @option.errors.full_messages })
    end
  end

  # PATCH/PUT /api/v1/admin/questions/:question_id/options/:id
  def update
    authorize @question.assessment, :manage_questions?

    if @option.update(option_params)
      @data = { option: @option }
      note!("Question option updated successfully")
    else
      raise ApiException::ValidationError.new("Option update failed",
                                              details: { errors: @option.errors.full_messages })
    end
  end

  # DELETE /api/v1/admin/questions/:question_id/options/:id
  def destroy
    authorize @question.assessment, :manage_questions?

    # Check minimum options requirement
    if @question.assessment_question_options.count <= 2
      raise ApiException::ValidationError.new("Cannot delete option - minimum 2 options required",
                                              details: {
                                                current_options_count: @question.assessment_question_options.count,
                                                minimum_required: 2,
                                              })
    end

    # Check if option has been selected in responses
    if @option.selected_options.exists?
      raise ApiException::ValidationError.new("Cannot delete option with existing selections",
                                              details: {
                                                selections_count: @option.selected_options.count,
                                                suggestion: "Archive the option instead of deleting it",
                                              })
    end

    option_text = @option.text["en"] || @option.text.values.first || "Option"
    if @option.destroy
      @data = { deleted_id: @option.id }
      note!("Question option '#{option_text}' deleted successfully")
    else
      raise ApiException::ValidationError.new("Option deletion failed",
                                              details: { errors: @option.errors.full_messages })
    end
  end

  # POST /api/v1/admin/questions/:question_id/options/reorder
  def reorder
    authorize @question.assessment, :manage_questions?

    option_orders = params.require(:option_orders)

    unless option_orders.is_a?(Array)
      raise ApiException::ValidationError.new("option_orders must be an array")
    end

    ActiveRecord::Base.transaction do
      option_orders.each_with_index do |option_id, index|
        option = @question.assessment_question_options.find(option_id)
        option.update!(order: index + 1)
      end
    end

    # Reload options with new order
    reordered_options = @question.assessment_question_options.order(:order)

    @data = {
      options: reordered_options,
      reordered_count: option_orders.length,
    }
    note!("Question options reordered successfully")

    render :reorder
  rescue ActiveRecord::RecordNotFound => e
    raise ApiException::NotFoundError.new("Option not found: #{e.message}")
  rescue ActiveRecord::RecordInvalid => e
    raise ApiException::ValidationError.new("Reorder failed: #{e.message}")
  end

  private

  def set_question
    @question = AssessmentQuestion.find(params[:question_id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Assessment question not found")
  end

  def set_option
    @option = @question.assessment_question_options.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Question option not found")
  end

  def option_params
    params.require(:option).permit(
      :order, :is_correct_answer, :points,
      text: {}, metadata: {},
    )
  end

  def calculate_selection_percentage(option)
    total_responses = @question.assessment_question_responses.count
    return 0 if total_responses.zero?

    selections = option.selected_options.count
    ((selections.to_f / total_responses) * 100).round(2)
  end
end
